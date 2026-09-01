pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.modules.common

Singleton {
    id: root

    readonly property list<var> feeds: Config.options.sidebar.widgets.news.feeds
    readonly property int fetchInterval: Config.options.sidebar.widgets.news.fetchInterval * 60 * 1000
    readonly property int maxItemsPerFeed: Config.options.sidebar.widgets.news.maxItemsPerFeed

    property var groups: []
    property bool loading: false

    property var __pending: ({}) // url -> parsed items, filled in as requests complete

    // Feed entries are normally { url, name, icon }, but plain url strings
    // (old config.json written before grouping) are accepted too.
    function feedMeta(entry) {
        if (typeof entry === "string") {
            const host = entry.replace(/^https?:\/\//, "").split("/")[0];
            return { url: entry, name: host, icon: "newspaper" };
        }
        return entry;
    }

    function parseDate(str) {
        const t = Date.parse(str || "");
        return isNaN(t) ? 0 : t;
    }

    // Qt/QML's XMLHttpRequest.responseXML is a minimal DOM Level 2 node tree
    // (nodeName/childNodes/attributes only) with no getElementsByTagName or
    // querySelector, so feed items are located by a manual tree walk.
    function findDescendants(node, tagName, results) {
        if (!node || !node.childNodes) return;
        for (let i = 0; i < node.childNodes.length; i++) {
            const child = node.childNodes[i];
            if (child.nodeName === tagName) results.push(child);
            root.findDescendants(child, tagName, results);
        }
    }

    function findChild(node, tagName) {
        if (!node || !node.childNodes) return null;
        for (let i = 0; i < node.childNodes.length; i++) {
            if (node.childNodes[i].nodeName === tagName) return node.childNodes[i];
        }
        return null;
    }

    function textOf(node) {
        if (!node || !node.childNodes) return "";
        let text = "";
        for (let i = 0; i < node.childNodes.length; i++) {
            const c = node.childNodes[i];
            if (c.nodeType === 3 || c.nodeType === 4) // TEXT_NODE / CDATA_SECTION_NODE
                text += c.nodeValue ?? "";
        }
        return text.trim();
    }

    function attrOf(node, name) {
        if (!node || !node.attributes) return "";
        for (let i = 0; i < node.attributes.length; i++) {
            if (node.attributes[i].nodeName === name) return node.attributes[i].nodeValue;
        }
        return "";
    }

    // Qt's XML DOM strips the namespace prefix from nodeName, so a
    // "media:content" element shows up here as just "content" — match on
    // the local name and require a "url" attribute to avoid colliding with
    // an unrelated bare <content> element (e.g. Atom's text body).
    function findMediaChild(node, localName) {
        if (!node || !node.childNodes) return null;
        for (let i = 0; i < node.childNodes.length; i++) {
            const child = node.childNodes[i];
            const name = child.nodeName || "";
            const local = name.includes(":") ? name.split(":").pop() : name;
            if (local === localName && root.attrOf(child, "url")) return child;
        }
        return null;
    }

    // Thumbnails show up as media:thumbnail, media:content (medium="image"),
    // or an <enclosure type="image/..."> — try each in that order.
    function findThumbnail(el) {
        const thumb = root.findMediaChild(el, "thumbnail");
        if (thumb) return root.attrOf(thumb, "url");

        const media = root.findMediaChild(el, "content");
        if (media && (root.attrOf(media, "medium") === "image" || root.attrOf(media, "type").startsWith("image")))
            return root.attrOf(media, "url");

        const enclosure = root.findChild(el, "enclosure");
        if (enclosure && root.attrOf(enclosure, "type").startsWith("image"))
            return root.attrOf(enclosure, "url");

        return "";
    }

    function parseFeed(xml, sourceUrl) {
        if (!xml || !xml.documentElement) return [];
        const host = sourceUrl.replace(/^https?:\/\//, "").split("/")[0];
        const out = [];

        const rssItems = [];
        root.findDescendants(xml.documentElement, "item", rssItems);
        for (const el of rssItems) {
            const title = root.textOf(root.findChild(el, "title"));
            const link = root.textOf(root.findChild(el, "link"));
            const pubDate = root.textOf(root.findChild(el, "pubDate"));
            const thumbnail = root.findThumbnail(el);
            if (title) out.push({ title, link, source: host, date: root.parseDate(pubDate), thumbnail });
        }

        const atomEntries = [];
        root.findDescendants(xml.documentElement, "entry", atomEntries);
        for (const el of atomEntries) {
            const title = root.textOf(root.findChild(el, "title"));
            const linkEl = root.findChild(el, "link");
            const link = linkEl ? root.attrOf(linkEl, "href") : "";
            const updated = root.textOf(root.findChild(el, "updated"));
            const thumbnail = root.findThumbnail(el);
            if (title) out.push({ title, link, source: host, date: root.parseDate(updated), thumbnail });
        }

        return out;
    }

    function mergePending() {
        const groups = [];
        for (const entry of root.feeds) {
            const meta = root.feedMeta(entry);
            const items = root.__pending[meta.url];
            if (!items || items.length === 0) continue;
            const sorted = items.slice().sort((a, b) => b.date - a.date).slice(0, root.maxItemsPerFeed);
            groups.push({ name: meta.name, icon: meta.icon, url: meta.url, items: sorted, latest: sorted[0].date });
        }
        groups.sort((a, b) => b.latest - a.latest);
        root.groups = groups;
    }

    function fetchOne(url) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status < 200 || xhr.status >= 300) {
                console.error(`[NewsService] Fetch failed for ${url} with status ${xhr.status}`);
                root.__pending[url] = [];
                root.mergePending();
                return;
            }
            try {
                root.__pending[url] = root.parseFeed(xhr.responseXML, url);
            } catch (e) {
                console.error(`[NewsService] ${e.message}`);
                root.__pending[url] = [];
            }
            root.mergePending();
        };
        xhr.open("GET", url);
        xhr.overrideMimeType("text/xml"); // some feeds serve application/rss+xml, which leaves responseXML null otherwise
        xhr.setRequestHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) quickshell-news-widget"); // some feeds 403 on non-browser UAs
        xhr.send();
    }

    function refresh() {
        if (root.feeds.length === 0) {
            root.groups = [];
            return;
        }
        root.loading = true;
        root.__pending = {};
        for (const entry of root.feeds) {
            root.fetchOne(root.feedMeta(entry).url);
        }
        refreshDoneTimer.restart();
    }

    // No per-request completion signal to aggregate on cleanly, so just
    // clear the loading flag shortly after kicking every request off.
    Timer {
        id: refreshDoneTimer
        interval: 5000
        onTriggered: root.loading = false
    }

    Timer {
        running: true
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
