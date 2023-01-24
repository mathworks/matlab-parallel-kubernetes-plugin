#!/usr/bin/env sh
# Sleep until the desired number of pods is running.
#
# Copyright 2022 The MathWorks, Inc.
set -o nounset

main() {
    local nRunning
    nRunning=$(countRunningPods)
    while [ "${nRunning}" -lt "${NUMBER_OF_TASKS}" ]; do
        sleep 1
        nRunning=$(countRunningPods)
    done
}

# Count pods in the "Running" phase
countRunningPods() {
    local phases
    phases=$(${KUBECTL} get pods -l jobUID="${JOB_UID}" -o jsonpath='{range .items[*]}{.status.phase}{"\n"}{end}')
    echo "${phases}" | grep "Running" | wc -w
}

main
