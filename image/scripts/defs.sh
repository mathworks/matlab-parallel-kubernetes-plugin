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
