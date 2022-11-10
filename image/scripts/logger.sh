#!/bin/bash
# Echo a log message to both the MATLAB logfile and to stdout (which goes to
# the Kubernetes log)
#
# Copyright 2022 The MathWorks, Inc.

# Set logfile path and parse PARALLEL_SERVER_DEBUG setting
setupLogging() {
    local validDebugSettings="true 0 1 2 3 4 5 6"
    for setting in $validDebugSettings; do
        if [[ ${PARALLEL_SERVER_DEBUG} == ${setting} ]]; then
            if [[ ${PARALLEL_SERVER_DEBUG} == "true" ]]; then
                export DEBUG_LEVEL=6
            else
                export DEBUG_LEVEL=${PARALLEL_SERVER_DEBUG}
            fi
            export LOGFILE_FULL="${PARALLEL_SERVER_STORAGE_LOCATION}/${LOGFILE}"
            return
        fi
    done

    # If logging has not been turned on, MATLAB output will be piped to /dev/null
    export LOGFILE_FULL="/dev/null"
    export DEBUG_LEVEL=""
}


# Write a message to logfile and echo to Kubernetes logs
logMessage() {
    if [[ $# -ne 3 ]]; then
        echo "number of inputs: $#"
        echo "inputs: $*"
        echo "Usage: $(basename $0) <debugLevel> <originScript> <message>"
        exit -1
    fi

    local level=$1
    local originScript=$2
    local message=$3

    [[ -z ${DEBUG_LEVEL} ]] && return

    if [[ ${level} -le ${DEBUG_LEVEL} ]]; then
        local timeInfo=$(date "+%Y %m %d %T UTC" --utc)
        local logMessage="${timeInfo} | ${level} | ${originScript} | ${message}"
        if [[ -w ${PARALLEL_SERVER_STORAGE_LOCATION} ]]; then
            echo $logMessage >> ${LOGFILE_FULL}
        fi
        echo $logMessage
    fi
}

set +o nounset
if [[ -z ${LOGFILE_FULL} ]]; then
    setupLogging
fi
set -o nounset

logMessage "$@"
