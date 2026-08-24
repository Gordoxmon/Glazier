pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

// Notes:
// We deal with keybinds being numbered 1, 2, etc by discarding 2+, keeping 1 and replacing it with a generic "<Number>"
Column {
    id: root
    required property string categoryName
    readonly property bool isCategorized: categoryName?.length > 0
    property int maxBindWidth: 0
    property real columnSpacing: 40
    property real titleSpacing: 7

    // Excellent symbol explaination and source :
    // http://xahlee.info/comp/unicode_computing_symbols.html
    // https://www.nerdfonts.com/cheat-sheet
    property var macSymbolMap: ({
        "Ctrl": "󰘴",
        "Alt": "󰘵",
        "Shift": "󰘶",
        "Space": "󱁐",
        "Tab": "↹",
        "Equal": "󰇼",
        "Minus": "",
        "Print": "",
        "BackSpace": "󰭜",
        "Delete": "⌦",
        "Return": "󰌑",
        "Period": ".",
        "Escape": "⎋"
      })
    property var functionSymbolMap: ({
        "F1":  "󱊫",
        "F2":  "󱊬",
        "F3":  "󱊭",
        "F4":  "󱊮",
        "F5":  "󱊯",
        "F6":  "󱊰",
        "F7":  "󱊱",
        "F8":  "󱊲",
        "F9":  "󱊳",
        "F10": "󱊴",
        "F11": "󱊵",
        "F12": "󱊶",
    })

    property var mouseSymbolMap: ({
        "mouse_up": "󱕐",
        "mouse_down": "󱕑",
        "mouse:272": "L󰍽",
        "mouse:273": "R󰍽",
        "Scroll ↑/↓": "󱕒",
        "Page_↑/↓": "⇞/⇟",
    })

    property var keyBlacklist: ["SUPER_L", "SUPER_R"]
    property var keySubstitutions: Object.assign({
        "Super": "",
        "mouse_up": "Scroll ↓",    // ikr, weird
        "mouse_down": "Scroll ↑",  // trust me bro
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "mouse:275": "MouseBack",
        "Slash": "/",
        "Hash": "#",
        "Return": "Enter",
        // "Shift": "",
      },
      !!Config.options.cheatsheet.superKey ? {
          "Super": Config.options.cheatsheet.superKey,
      }: {},
      Config.options.cheatsheet.useMacSymbol ? macSymbolMap : {},
      Config.options.cheatsheet.useFnSymbol ? functionSymbolMap : {},
      Config.options.cheatsheet.useMouseSymbol ? mouseSymbolMap : {},
    )

    function modMaskToStringList(modMask: int): list<string> {
        var list = [];
        // Funny mathematical order but we wanna have this natural user-facing order
        if (modMask & (1 << 2)) { list.push("Ctrl"); }
        if (modMask & (1 << 6)) { list.push("Super"); }
        if (modMask & (1 << 0)) { list.push("Shift"); }
        if (modMask & (1 << 3)) { list.push("Alt"); }
        if (modMask & (1 << 1)) { list.push("Caps"); }
        if (modMask & (1 << 4)) { list.push("Mod2"); }
        if (modMask & (1 << 5)) { list.push("Mod3"); }
        if (modMask & (1 << 7)) { list.push("Mod5"); }
        return list;
    }

    visible: repeater.model.length > 0
    spacing: titleSpacing

    StyledText {
        text: root.isCategorized ? root.categoryName : "Uncategorized"
        font.pixelSize: Appearance.font.pixelSize.title
    }

    function hasDescription(bind) {
        return bind.description?.length > 0;
    }

    function isCategory(bind, categoryName) {
        return bind.description.substring(0, bind.description.indexOf(":")) === categoryName;
    }

    function isUncategorized(bind) {
        return bind.description.indexOf(":") === -1;
    }

    // LOCAL CHANGE (2026-08-23, ADR-0009). The three functions below collapse
    // repeated bindings — the ten workspace keys become one "<Number>" row, the
    // four arrows become one "<Direction>" row. Upstream matched on "contains",
    // which is too loose in two ways that both show up on this machine:
    //
    //   F1 contains a "1", so the cheatsheet key rendered as "F<Number>". Ours
    //   binds the cheatsheet itself to SUPER+F1, so the one row a first-time
    //   user goes looking for was the broken one. Upstream never sees this
    //   because SUPER+Slash has no digit in it.
    //
    //   hyprctl reports arrow keys lowercase ("left"), and the replace looked
    //   for "Left", so the key column never generalised while the description
    //   column did — "left" paired with "Focus <Direction>".
    //
    // Both fixed by matching the WHOLE key instead of a substring. A key is a
    // repetition if it IS a digit, not if it merely contains one.
    function containsNonFirstRepetitive(bind) {
        const key = bind.key;
        if (key.includes("mouse") || key.includes("page")) return false;
        // A bare number other than 1 — the 2..9,0 workspace keys
        if (/^\d+$/.test(key) && key !== "1") return true;
        // A direction other than left
        if (/^(right|up|down)$/i.test(key)) return true;
        return false;
    }

    function containsFirstRepetitive(bind) {
        const key = bind.key;
        return key === "1" || /^left$/i.test(key);
    }

    // LOCAL CHANGE (2026-08-24, ADR-0009). Media keys arrive from hyprctl under
    // their raw X11 names — XF86AudioRaiseVolume, XF86MonBrightnessDown — and
    // upstream's keySubstitutions map has no entry for any of them, so the
    // cheatsheet printed the identifier verbatim. Eleven rows of "XF86Audio..."
    // is the widest column on the page and the least readable thing on it.
    //
    // Derived rather than tabulated: drop the XF86 prefix, drop the Audio/Mon
    // namespace, then split the camel humps. RaiseVolume becomes "Raise Volume",
    // MonBrightnessUp becomes "Brightness Up", AudioMicMute becomes "Mic Mute".
    // A table would have to be extended every time a key is bound that nobody
    // thought of; this handles XF86Search or XF86Calculator on the day someone
    // binds one, without being touched.
    //
    // keySubstitutions still wins if it has an entry, so an explicit override
    // remains possible.
    function prettifyMediaKey(key) {
        if (!key.startsWith("XF86")) return key;
        return key.slice(4)
            .replace(/^(Audio|Mon)/, "")
            .replace(/([a-z])([A-Z])/g, "$1 $2");
    }

    function transformKey(key) {
        const replaced = root.keySubstitutions[key] || root.prettifyMediaKey(key);
        const denumbered = (replaced === "1") ? "<Number>" : replaced;
        const dedirectioned = /^left$/i.test(denumbered) ? "<Direction>" : denumbered;
        return dedirectioned;
    }

    function transformDescription(bind, categoryName) {
        const description = bind.description
        const regex = new RegExp("\\s*" + categoryName + "\\s*:\\s*");
        const decategorized = description.replace(regex, "");
        if (!containsFirstRepetitive(bind)) return decategorized;
        const denumbered = decategorized.replace("1", "<Number>");
        const dedirectioned = denumbered.replace(/ \b(left|right|up|down)\b/i, " <Direction>");
        return dedirectioned;
    }

    Column {
        spacing: 4
        Repeater {
            id: repeater
            model: {
                if (!root.isCategorized) {
                    return HyprlandKeybinds.keybinds.filter(bind => root.hasDescription(bind) && root.isUncategorized(bind) && !root.containsNonFirstRepetitive(bind));
                }
                return HyprlandKeybinds.keybinds.filter(bind => root.hasDescription(bind) && root.isCategory(bind, root.categoryName) && !root.containsNonFirstRepetitive(bind));
            }
            delegate: BindLine {
                required property var modelData
                keyData: modelData
                categoryName: root.categoryName
            }
        }
    }

    component BindLine: Row {
        id: bindLine
        required property var keyData
        property string categoryName: ""

        Row {
            spacing: 16
            Row {
                id: modRow
                Component.onCompleted: root.maxBindWidth = Math.max(root.maxBindWidth, implicitWidth)
                width: root.maxBindWidth
                spacing: 4
                Repeater {
                    model: {
                        const modList = root.modMaskToStringList(bindLine.keyData.modmask).map(mod => root.keySubstitutions[mod] || mod)
                        if (modList.length == 0) return []
                        if (Config.options.cheatsheet.splitButtons) return modList;
                        return [modList.join(" ")]
                    }
                    delegate: KeyboardKey {
                        required property var modelData
                        key: root.transformKey(modelData)
                        pixelSize: Config.options.cheatsheet.fontSize.key
                    }
                }
                StyledText {
                    id: keybindPlus
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !keyBlacklist.includes(bindLine.keyData.key) && bindLine.keyData.modmask > 0
                    text: "+"
                }
                KeyboardKey {
                    id: keybindKey
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !keyBlacklist.includes(bindLine.keyData.key)
                    key: root.transformKey(bindLine.keyData.key)
                    pixelSize: Config.options.cheatsheet.fontSize.key
                    color: Appearance.colors.colOnLayer0
                }
            }
            Item {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: commentText.implicitWidth + root.columnSpacing
                implicitHeight: commentText.implicitHeight
                StyledText {
                    id: commentText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    font.pixelSize: Config.options.cheatsheet.fontSize.comment || Appearance.font.pixelSize.smaller
                    text: root.transformDescription(bindLine.keyData, bindLine.categoryName)
                }
            }
        }
    }
}