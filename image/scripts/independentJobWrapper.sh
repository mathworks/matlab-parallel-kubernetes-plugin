#!/usr/bin/env sh
# Script to be run by each independent job pod on startup. Launches a MATLAB
# worker.
#
# Exit codes:
# 2: Incorrect write permission for the job storage location.
# 5: MATLAB executable not found.
#
# Copyright 2022-2023 The MathWorks, Inc.
set -o nounset

main() {
    . /scripts/defs.sh
    initialChecks

    logger 4 "Running $(basename $0) as user with uid=$(id -u), gid=$(id -g)"
    setHome
    trap "rm -r $HOME" EXIT

    runMatlab
}

# Check this job can run
initialChecks() {
    local err
    local exitCode
    err=$(. /scripts/initialChecks.sh)
    exitCode=$?
    if [ ${exitCode} -ne 0 ]; then
        logger 0 "${err}"
        exit ${exitCode}
    fi
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
    exit ${exitCode}
}

# Write log entry
logger() {
    local level="$1"
    local message="$2"
    ${RUNCMD} /scripts/logger.sh "${level}" "$(basename $0)" "${message}"
}

main
