#!/usr/bin/env sh
# Get IP addresses of pods associated with a given job UID.
#
# Copyright 2022 The MathWorks, Inc.
set -o nounset

main() {
    local ips
    ips=$(${KUBECTL} get pods -l jobUID="${JOB_UID}" -o jsonpath='{range .items[*]}{.status.podIP}{"\n"}{end}')
    echo "${ips}" | xargs
}

main "$@"
