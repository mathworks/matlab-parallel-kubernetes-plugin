#!/usr/bin/env sh
# Check we have write permissions for the job storage location. If not, return
# error message.
#
# Copyright 2022 The MathWorks, Inc.

if [ ! -w "${PARALLEL_SERVER_STORAGE_LOCATION}" ]; then
    echo "Error: user does not have permission to write to the job storage location on the cluster (uid=$(id -u), gid=$(id -g))"
fi
