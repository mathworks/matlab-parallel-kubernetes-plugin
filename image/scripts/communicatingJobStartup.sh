#!/usr/bin/env sh
# Script to be run by each communicating job pod upon startup. Creates a user
# account for a given user ID and sets up ssh.
#
# Exits with code 2 if we don't have permission to write to the job storage location.
#
# Copyright 2022 The MathWorks, Inc.
set -o nounset

_USER_HOME=/home/${PARALLEL_SERVER_USERNAME}

main() {
    . /scripts/defs.sh
    addUser

    # Exit if we don't have write permission for the job storage location
    local permissionErr
    permissionErr=$(su "${PARALLEL_SERVER_USERNAME}" -c ". /scripts/checkWritePermission.sh")
    if [ -n "${permissionErr}" ]; then
        logger 0 "${permissionErr}"
        exit "${EXIT_CODE_WRITE_PERMISSION}"
    fi

    setupSshKeys
    startSshDaemon
    indicateReady
}

# Create an account and home directory with the name of the user on the client machine.
addUser() {
    logger 4 "Adding user ${PARALLEL_SERVER_USERNAME} with uid=${PARALLEL_SERVER_USER_ID}, gid=${PARALLEL_SERVER_GROUP_ID} and home directory ${_USER_HOME}"
    groupadd --force --gid "${PARALLEL_SERVER_GROUP_ID}" workers
    useradd --uid "${PARALLEL_SERVER_USER_ID}" --gid "${PARALLEL_SERVER_GROUP_ID}" --create-home --home-dir "${_USER_HOME}" "${PARALLEL_SERVER_USERNAME}"
    local randomPassword
    randomPassword=$(awk 'BEGIN { srand(); print int(rand()*32768) }' /dev/null)
    echo "${PARALLEL_SERVER_USERNAME}:${randomPassword}" | chpasswd
}

# Copy SSH keys into home directory and set permissions.
setupSshKeys() {
    logger 4 "Setting up SSH keys in ${_USER_HOME}/.ssh"
    mkdir "${_USER_HOME}/.ssh"
    cp /config/ssh_config "${_USER_HOME}/.ssh/config"
    cp /ssh-keys/id_rsa /ssh-keys/id_rsa.pub "${_USER_HOME}/.ssh"
    cp "${_USER_HOME}/.ssh/id_rsa.pub" "${_USER_HOME}/.ssh/authorized_keys"

    # The ssh directory and its contents are required to have specific permissions
    chown -R "${PARALLEL_SERVER_USERNAME}" "${_USER_HOME}/.ssh"
    chmod 700 "${_USER_HOME}/.ssh"
    chmod 600 "${_USER_HOME}/.ssh/config"
    chmod 600 "${_USER_HOME}/.ssh/id_rsa"
    chmod 644 "${_USER_HOME}/.ssh/id_rsa.pub"
}

startSshDaemon() {
    logger 4 "Launching SSH daemon"
    /usr/sbin/sshd
}

# Create file to indicate worker startup is done.
indicateReady() {
    logger 4 "Worker setup complete"
    su "${PARALLEL_SERVER_USERNAME}" -c "touch ${PARALLEL_SERVER_STORAGE_LOCATION}/${PARALLEL_SERVER_JOB_LOCATION}/$(hostname).ready"
}

main
