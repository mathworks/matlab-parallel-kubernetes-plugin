#!/bin/bash
# Run by each secondary worker pod in a communicating job.
#
# Copyright 2022 The MathWorks, Inc.
set -o nounset

main() {

    . /scripts/communicatingJobStartup.sh
    runUntilJobComplete
}

# Keep this pod running until the entire job is complete
runUntilJobComplete() {
    logger 4 "Waiting for primary pod to finish"
    while true
    do
        if [[ -f "${PARALLEL_SERVER_STORAGE_LOCATION}/${PARALLEL_SERVER_JOB_LOCATION}.done" ]]
        then
            logger 4 "Found file indicating that primary pod is complete"
            exit 0
        fi
        sleep 1
    done
}

# Write log entry
logger() {
    local level=$1
    local message=$2
    . /scripts/logger.sh "${level}" "secondaryWorker.sh" "${message}"
}

main
