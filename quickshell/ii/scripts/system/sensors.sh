#!/usr/bin/env bash
# Prints one line: <cpuTempC>|<gpuBackend>|<gpuUsagePercent>|<gpuTempC>|<gpuMemUsedMiB>|<gpuMemTotalMiB>|<gpuName>
# Missing values are "-1" (or "none" for gpuBackend/gpuName) so callers can
# treat them as "unavailable" rather than fail to parse.
set -uo pipefail

cpu_temp="-1"
for hw in /sys/class/hwmon/hwmon*; do
    name=$(cat "$hw/name" 2>/dev/null)
    case "$name" in
        coretemp|k10temp|zenpower)
            t=$(cat "$hw/temp1_input" 2>/dev/null)
            if [[ -n "$t" ]]; then
                cpu_temp=$((t / 1000))
                break
            fi
            ;;
    esac
done

gpu_backend="none"
gpu_usage="-1"
gpu_temp="-1"
gpu_mem_used="-1"
gpu_mem_total="-1"
gpu_name="none"

if command -v nvidia-smi >/dev/null 2>&1; then
    line=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,name \
        --format=csv,noheader,nounits 2>/dev/null | head -n1)
    if [[ -n "$line" ]]; then
        gpu_backend="nvidia"
        IFS=',' read -r gpu_usage gpu_temp gpu_mem_used gpu_mem_total gpu_name <<< "$line"
        gpu_usage=$(echo "$gpu_usage" | xargs)
        gpu_temp=$(echo "$gpu_temp" | xargs)
        gpu_mem_used=$(echo "$gpu_mem_used" | xargs)
        gpu_mem_total=$(echo "$gpu_mem_total" | xargs)
        gpu_name=$(echo "$gpu_name" | xargs)
    fi
fi

if [[ "$gpu_backend" == "none" ]]; then
    for hw in /sys/class/hwmon/hwmon*; do
        name=$(cat "$hw/name" 2>/dev/null)
        if [[ "$name" == "amdgpu" ]]; then
            t=$(cat "$hw/temp1_input" 2>/dev/null)
            [[ -n "$t" ]] && gpu_temp=$((t / 1000))

            card_dev=$(readlink -f "$hw/device")
            for card in /sys/class/drm/card*/device; do
                if [[ "$(readlink -f "$card")" == "$card_dev" ]]; then
                    busy=$(cat "$card/gpu_busy_percent" 2>/dev/null)
                    [[ -n "$busy" ]] && gpu_usage="$busy"

                    used=$(cat "$card/mem_info_vram_used" 2>/dev/null)
                    total=$(cat "$card/mem_info_vram_total" 2>/dev/null)
                    [[ -n "$used" ]] && gpu_mem_used=$((used / 1024 / 1024))
                    [[ -n "$total" ]] && gpu_mem_total=$((total / 1024 / 1024))
                    break
                fi
            done

            gpu_backend="amdgpu"
            gpu_name="AMD GPU"
            break
        fi
    done
fi

echo "${cpu_temp}|${gpu_backend}|${gpu_usage}|${gpu_temp}|${gpu_mem_used}|${gpu_mem_total}|${gpu_name}"
