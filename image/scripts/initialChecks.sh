#!/usr/bin/env sh
# Initial checks to perform for all job types. If these checks fail, the
# job cannot run.
#
# Copyright 2023 The MathWorks, Inc.
set -o nounset

main() {
   checkJobStorage
   checkMatlabExecutable
}

checkJobStorage() {
    # Check the job storage location exists
    if [ ! -d "${PARALLEL_SERVER_STORAGE_LOCATION}" ]; then
        echo "Error: job storage location ${PARALLEL_SERVER_STORAGE_LOCATION} not found"
        exit ${EXIT_CODE_MISSING_JOB_STORAGE}
    fi

    # Check we have write permission for the job storage location
    if [ ! -w "${PARALLEL_SERVER_STORAGE_LOCATION}" ]; then
        echo "Error: user does not have permission to write to the job storage location on the cluster (uid=$(id -u), gid=$(id -g))"
        exit ${EXIT_CODE_WRITE_PERMISSION}
    fi
}

checkMatlabExecutable() {
    local matlabWorker="${MATLAB_ROOT}/bin/worker"
    if [ ! -f "${MATLAB_ROOT}/bin/worker" ]; then
        echo "Error: MATLAB worker executable ${matlabWorker} not found"
        exit ${EXIT_CODE_MISSING_MATLAB}
    fi
}

main
