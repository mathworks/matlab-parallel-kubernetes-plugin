#!/usr/bin/env sh
# Script to be run by each independent job pod on startup. Launches a MATLAB
# worker.
#
# Exits with code 2 if we don't have permission to write to the job storage location.
#
# Copyright 2022 The MathWorks, Inc.
set -o nounset

main() {
    . /scripts/defs.sh

    # Exit if we don't have write permission for the job storage location
    local permissionErr
    permissionErr=$(. /scripts/checkWritePermission.sh)
    if [ -n "${permissionErr}" ]; then
        logger 0 "${permissionErr}"
        logger 0 "Terminating job"
        exit "${EXIT_CODE_WRITE_PERMISSION}"
    fi

    logger 4 "Running $(basename $0) as user with uid=$(id -u), gid=$(id -g)"
    setHome
    trap "rm -r $HOME" EXIT
    runMatlab
}

# Create temporary home directory in the job storage location
setHome() {
    export HOME="${PARALLEL_SERVER_STORAGE_LOCATION}/${PARALLEL_SERVER_TASK_LOCATION}_home"
    mkdir "$HOME"
    logger 4 "Set home directory to ${HOME}"
}

# Launch a MATLAB worker
runMatlab() {
    logger 4 "Running MATLAB worker"
    "${MATLAB_ROOT}/bin/worker" "${PARALLEL_SERVER_MATLAB_ARGS}" >> "${LOGFILE_FULL}"
    local exitCode=$?
    logger 0 "Exited MATLAB with code: ${exitCode}"
}

# Write log entry
logger() {
    local level="$1"
    local message="$2"
    ${RUNCMD} /scripts/logger.sh "${level}" "$(basename $0)" "${message}"
}

main
