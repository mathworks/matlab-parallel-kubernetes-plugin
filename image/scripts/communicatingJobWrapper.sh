#!/usr/bin/env sh
# Script to be run by each communicating job pod.
#
# Exit codes:
# 2: Incorrect write permission for the job storage location.
# 3: Timed out waiting for all workers to start after the primary worker.
# 5: MATLAB executable not found.
# 6: Timed out waiting for primary worker to share public SSH key with secondary workers.
#
# Copyright 2023 The MathWorks, Inc.
set -o nounset

_SSH_KEY_DIR="/ssh-keys"
_JOB_LOC="${PARALLEL_SERVER_STORAGE_LOCATION}/${PARALLEL_SERVER_JOB_LOCATION}"
_PUBLIC_SSH_KEY="${_JOB_LOC}/id_rsa.pub"
_PRIMARY_IP_FILE="${_JOB_LOC}/Task1.ip"
_JOB_DONE_FILE="${_JOB_LOC}/done"
_JOB_ERROR_FILE="${_JOB_LOC}/error"

main() {
    . /scripts/defs.sh
    if [ "${IS_PRIMARY}" = "true" ]; then
        trap "finish" EXIT
        generateSSHKeys
    fi

    setupWorker

    if [ "${IS_PRIMARY}" = "true" ]; then
        executePrimaryWorker
    else
        executeSecondaryWorker
    fi
}

# Generate SSH keys and share the public key via the job storage location
generateSSHKeys() {
    mkdir ${_SSH_KEY_DIR}
    logger 4 "Generating SSH keys"
    ssh-keygen -f ${_SSH_KEY_DIR}/id_rsa -t rsa -N "" > /dev/null
    cp "${_SSH_KEY_DIR}/id_rsa.pub" "${_PUBLIC_SSH_KEY}"
}

# Setup tasks to be performed by all workers
setupWorker() {
    addUser
    initialChecks
}

# The primary worker finds the IP addresses of all workers and launches an MPI ring.
executePrimaryWorker() {
    setupSSHConfig
    writeIP
    copyPrivateSSHKey
    waitForIPs

    # Replace spaces with commas to obtain format "ADDRESS1,ADDRESS2,...,ADDRESSN"
    local addresses
    addresses=$(${RUNCMD} /scripts/getPodIPs.sh | xargs | sed 's/ /,/g')

    local thisHostname="${HOSTNAME}"
    unset HOSTNAME
    unset HOST

    local cmd="${MATLAB_ROOT}/bin/mw_mpiexec -hosts ${addresses} /scripts/runMatlabWithHostnameOverride.sh ${PARALLEL_SERVER_MATLAB_ARGS} 2>&1"
    logger 4 "Running MATLAB: ${cmd}"
    su "${PARALLEL_SERVER_USERNAME}" -c "${cmd}" >> "${LOGFILE_FULL}"

    local exitCode=$?
    export HOSTNAME="${thisHostname}"
    logger 0 "Exited MATLAB with code: ${exitCode}"
    exit ${exitCode}
}

# Secondary workers copy the public SSH key, then wait for the primary worker to finish.
executeSecondaryWorker() {
    startSSHD
    waitForPrimaryIP
    copyPublicSSHKey
    allowSSHFromPrimaryWorker
    writeIP
    runUntilJobComplete
}

# Create an account and home directory with the name of the user on the client machine.
addUser() {
    logger 4 "Adding user ${PARALLEL_SERVER_USERNAME} with uid=${PARALLEL_SERVER_USER_ID}, gid=${PARALLEL_SERVER_GROUP_ID} and home directory ${USER_HOME}"
    groupadd --force --gid "${PARALLEL_SERVER_GROUP_ID}" workers
    useradd --uid "${PARALLEL_SERVER_USER_ID}" --gid "${PARALLEL_SERVER_GROUP_ID}" --create-home --home-dir "${USER_HOME}" "${PARALLEL_SERVER_USERNAME}"
    local randomPassword
    randomPassword=$(awk 'BEGIN { srand(); print int(rand()*32768) }' /dev/null)
    echo "${PARALLEL_SERVER_USERNAME}:${randomPassword}" | chpasswd
    mkdir "${USER_HOME}/.ssh"
}

# Check this job can run
initialChecks() {
    local err
    local exitCode
    err=$(su "${PARALLEL_SERVER_USERNAME}" -c ". /scripts/initialChecks.sh")
    exitCode=$?
    if [ ${exitCode} -ne 0 ]; then
        logger 0 "${err}"
        exit ${exitCode}
    fi
}

# Create SSH dir and copy in SSH config
setupSSHConfig() {
    local sshDir="${USER_HOME}/.ssh"
    cp /config/ssh_config "${sshDir}/config"

    # The ssh directory and its contents are required to have specific permissions
    chown -R "${PARALLEL_SERVER_USERNAME}" "${sshDir}"
    chmod 700 "${sshDir}"
    chmod 600 "${sshDir}/config"
}

startSSHD() {
    logger 4 "Launching sshd"
    /usr/sbin/sshd
}

# Create file containing this pod's IP address
writeIP() {
    logger 4 "Writing pod IP address to file"

    # Write IP address to job storage location; the primary worker uses this to start the MPI ring
    su "${PARALLEL_SERVER_USERNAME}" -c "echo ${POD_IP} > ${PARALLEL_SERVER_STORAGE_LOCATION}/${PARALLEL_SERVER_TASK_LOCATION}.ip"

    # Write IP address to a file on this container's filesystem; this is used later to set MDCE_OVERRIDE_EXTERNAL_HOSTNAME
    su "${PARALLEL_SERVER_USERNAME}" -c "echo ${POD_IP} > ${INTERNAL_IP_FILE}"
}

# Copy the private SSH key to the .ssh directory
copyPrivateSSHKey() {
    local privateKeyFile="${USER_HOME}/.ssh/id_rsa"
    cp "${_SSH_KEY_DIR}/id_rsa" "${privateKeyFile}"
    chown -R "${PARALLEL_SERVER_USERNAME}" "${privateKeyFile}"
    chmod 600 "${privateKeyFile}"
}

# Copy the public key to the .ssh directory
copyPublicSSHKey() {
    cp "${_PUBLIC_SSH_KEY}" "${USER_HOME}/.ssh/authorized_keys"
    logger 4 "Copied public SSH key"
}

# Wait for the primary worker to write its IP address to the job storage location
waitForPrimaryIP() {
    logger 4 "Waiting for primary worker IP address file"
    timeout "${TIMEOUT}" "${RUNCMD}" -c "while [ ! -f \"${_PRIMARY_IP_FILE}\" ]; do sleep 1; done"
    if [ $? -eq 124  ]; then
        logger 0 "Error: Timed out after ${TIMEOUT} seconds waiting for primary worker IP address file"
        exit "${EXIT_CODE_PRIMARY_IP_TIMEOUT}"
    fi
}

# Allow SSH from only the primary worker's IP address
allowSSHFromPrimaryWorker() {
    local ip
    ip=$(cat "${_PRIMARY_IP_FILE}")
    echo "sshd: ALL" > /etc/hosts.deny
    echo "sshd: ${ip}" > /etc/hosts.allow
    logger 4 "Allowed SSH from primary worker"
}

# Wait up to $TIMEOUT for all secondary pods to start running and share their
# IP addresses.
waitForIPs() {
    logger 4 "Waiting for secondary worker IP files"
    timeout "${TIMEOUT}" "${RUNCMD}" /scripts/waitForPodIPs.sh
    if [ $? -eq 124 ]; then
        logger 0 "Error: Timed out after ${TIMEOUT} seconds waiting for ${NUMBER_OF_TASKS} pods to start running."
        exit "${EXIT_CODE_TIMEOUT}"
    fi
}

# Indicate that job is done
finish() {
    exitCode=${?}
    if [ ${exitCode} -eq 0 ]; then
        indicateDone
    elif [ ${exitCode} -ne "${EXIT_CODE_WRITE_PERMISSION}" ]; then
        indicateError
    fi
    exit ${exitCode}
}

# Create a file to indicate that primary pod has finished.
indicateDone() {
    logger 4 "Primary worker execution complete"
    su "${PARALLEL_SERVER_USERNAME}" -c "touch ${_JOB_DONE_FILE}"
}

# Create a file to indicate an error in the primary pod
indicateError() {
    logger 4 "Primary worker exiting with error code"
    su "${PARALLEL_SERVER_USERNAME}" -c "touch ${_JOB_ERROR_FILE}"
}

# Keep running until the entire job is complete
runUntilJobComplete() {
    logger 4 "Waiting for primary pod to finish"
    while true
    do
        if [ -f "${_JOB_DONE_FILE}" ]
        then
            logger 4 "Found file indicating that primary pod is complete"
            exit 0
        elif [ -f "${_JOB_ERROR_FILE}" ]
        then
            logger 4 "Found file indicating that primary pod errored"
            exit "${EXIT_CODE_PRIMARY_WORKER_ERROR}"
        fi
        sleep 1
    done
}

# Write log entry
logger() {
    local level="$1"
    local message="$2"
    ${RUNCMD} /scripts/logger.sh "${level}" "$(basename "$0")" "${PARALLEL_SERVER_TASK_LOCATION}: ${message}"
}

main
