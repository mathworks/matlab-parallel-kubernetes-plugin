#!/usr/bin/env sh
# Sleep until all workers have shared their IP addresses.
#
# Copyright 2023 The MathWorks, Inc.
set -o nounset

main() {
    local nAddresses
    nAddresses=$(countIPs)
    while [ "${nAddresses}" -lt "${NUMBER_OF_TASKS}" ]; do
        sleep 1
        nAddresses=$(countIPs)
    done
}

# Count IP addresses
countIPs() {
    ${RUNCMD} /scripts/getPodIPs.sh | wc -l
}

main
