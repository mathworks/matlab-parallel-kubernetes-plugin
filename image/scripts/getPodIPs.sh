#!/usr/bin/env sh
# Find pod IP addresses in the job storage directory.
#
# Copyright 2022-2023 The MathWorks, Inc.
set -o nounset

main() {
    awk '{print $1}' "${PARALLEL_SERVER_STORAGE_LOCATION}/${PARALLEL_SERVER_JOB_LOCATION}"/*.ip 2>/dev/null
}

main
