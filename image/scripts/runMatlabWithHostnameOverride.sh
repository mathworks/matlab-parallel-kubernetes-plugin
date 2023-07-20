#!/usr/bin/env sh
# Override hostname with IP address to allow worker-worker communication, then run MATLAB.
# MDCE_OVERRIDE_INTERNAL_HOSTNAME must be overriden at this point so that it is not overwritten
# by mw_mpiexec when it forwards the environment from the primary worker.

# Copyright 2023 The MathWorks, Inc.
set -o nounset

main() {
    . /scripts/defs.sh
    overrideHostname
    "${MATLAB_ROOT}/bin/worker" "$@"
}

overrideHostname() {
    MDCE_OVERRIDE_INTERNAL_HOSTNAME=$(cat "${INTERNAL_IP_FILE}")
    export MDCE_OVERRIDE_INTERNAL_HOSTNAME
}

main "$@"
