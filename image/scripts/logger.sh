#!/usr/bin/env sh
# Echo a log message to both the MATLAB logfile and to stdout (which goes to
# the Kubernetes log)
#
# Copyright 2022 The MathWorks, Inc.
set -o nounset

main() {
    if [ $# -ne 3 ]; then
        echo "Usage: $(basename "$0") <debugLevel> <originScript> <message>"
        exit 1
    fi

    local level="$1"
    local originScript="$2"
    local message="$3"

    [ -z "${DEBUG_LEVEL}" ] && return

    if [ "${level}" -le "${DEBUG_LEVEL}" ]; then
        local timeInfo
        timeInfo=$(date "+%Y %m %d %T UTC" --utc)
        local logMessage
        logMessage="${timeInfo} | ${level} | ${originScript} | ${message}"

        if [ -w "${PARALLEL_SERVER_STORAGE_LOCATION}" ]; then
            echo "$logMessage" >> "${LOGFILE_FULL}"
        fi
        echo "$logMessage"
    fi
}

main "$@"
