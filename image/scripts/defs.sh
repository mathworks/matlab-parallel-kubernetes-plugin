#!/usr/bin/env sh
# Global variable definitions.
#
# Copyright 2022 The MathWorks, Inc.
set -o nounset

main() {
    # Shell command
    export RUNCMD=/bin/sh

    # Exit codes
    export EXIT_CODE_WRITE_PERMISSION=2
    export EXIT_CODE_TIMEOUT=3
    export EXIT_CODE_PRIMARY_WORKER_ERROR=4
    export EXIT_CODE_MISSING_MATLAB=5
    export EXIT_CODE_PRIMARY_IP_TIMEOUT=6
    export EXIT_CODE_MISSING_JOB_STORAGE=7

    # Location of home and IP address file for communicating job pods
    export USER_HOME="/home/${PARALLEL_SERVER_USERNAME}"
    export INTERNAL_IP_FILE="${USER_HOME}/ip"

    setupLogging
}

setupLogging() {
    local validDebugSettings="true 0 1 2 3 4 5 6"
    for setting in $validDebugSettings; do
        if [ "${PARALLEL_SERVER_DEBUG}" = "${setting}" ]; then
            if [ "${PARALLEL_SERVER_DEBUG}" = "true" ]; then
                export DEBUG_LEVEL=6
            else
                export DEBUG_LEVEL="${PARALLEL_SERVER_DEBUG}"
            fi
            export LOGFILE_FULL="${PARALLEL_SERVER_STORAGE_LOCATION}/${LOGFILE}"
            return
        fi
    done

    # If logging has not been turned on, MATLAB output will be piped to /dev/null
    export LOGFILE_FULL="/dev/null"
    export DEBUG_LEVEL=""
}

main
