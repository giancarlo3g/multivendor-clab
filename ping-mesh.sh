#!/usr/bin/env bash
# Full-mesh ping test between all lab clients over the VNI 1010 L2 stretch.
# Each mv-client-N (192.168.10.1N) pings every other client.
#
# Usage: ./ping-mesh.sh [count]    (default count: 3)

COUNT="${1:-3}"
CLIENTS=(1 2 3 4 5 6)
PREFIX="192.168.10.1"

pass=0
fail=0

for src in "${CLIENTS[@]}"; do
    container="mv-client-${src}"
    echo "=== ${container} (${PREFIX}${src}) ==="

    if ! docker inspect -f '{{.State.Running}}' "${container}" 2>/dev/null | grep -q true; then
        echo "  ${container} is not running, skipping"
        continue
    fi

    for dst in "${CLIENTS[@]}"; do
        [ "${src}" = "${dst}" ] && continue
        ip="${PREFIX}${dst}"
        if out=$(docker exec "${container}" ping -c "${COUNT}" -W 1 "${ip}" 2>&1); then
            loss=$(echo "${out}" | grep -oE '[0-9.]+% packet loss')
            rtt=$(echo "${out}" | grep -oE '= [0-9./]+ ms' | cut -d/ -f2)
            printf "  -> %-15s OK    (%s, avg %s ms)\n" "${ip}" "${loss}" "${rtt}"
            pass=$((pass + 1))
        else
            loss=$(echo "${out}" | grep -oE '[0-9.]+% packet loss')
            printf "  -> %-15s FAIL  (%s)\n" "${ip}" "${loss:-no reply}"
            fail=$((fail + 1))
        fi
    done
done

echo
echo "Summary: ${pass} OK, ${fail} FAIL"
[ "${fail}" -eq 0 ]
