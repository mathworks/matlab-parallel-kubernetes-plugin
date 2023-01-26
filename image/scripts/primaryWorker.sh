#!/usr/bin/env sh
# Run by the primary worker in a communicating job.
#
# Copyright 2022 The MathWorks, Inc.
#
# This script does the following:
# 1. Generate ssh keys and stores them in a kubernetes secret.
# 2. Run communicatingJobStartup.sh to perform setup for this pod.
# 3. Launch all other pods required for this job via helm.
# 4. Wait up to $TIMEOUT seconds for all pods in the job to start running; if the pods do not start within the timeout, uninstall the secondary pods and exit.
# 5. When all pods are running, run mw_mpiexec to launch an MPI ring between the workers.
# 6. When mw_mpiexec completes, create a file to indicate that the job is done and delete the kubernetes secret.
#
# Exit codes:
# 2: Incorrect write permission for the job storage location.
# 3: Timed out waiting for all workers to start after the primary worker.

set -o nounset

main() {
    . /scripts/defs.sh

    local secretName="${HELM_RELEASE_NAME}-ssh-keys-secret"
    createSecret "${secretName}"
    trap "finish ${secretName}" EXIT

    runJobStartup

    copyHelmValues
    waitForPrimaryIP

    installSecondaryWorkers "${secretName}"
    waitForSecondaryWorkers

    launchMpi
}

# Create ssh keys and store them in kubernetes secret.
createSecret() {
    local secretName="$1"
    local sshDir=/ssh-keys
    mkdir ${sshDir}
    ssh-keygen -f ${sshDir}/id_rsa -t rsa -N "" > /dev/null
    logger 4 "Creating Kubernetes secret ${secretName} containing SSH keys"
    ${KUBECTL} create secret generic "${secretName}" \
        --from-file=id_rsa=${sshDir}/id_rsa \
        --from-file=id_rsa.pub=${sshDir}/id_rsa.pub > /dev/null
}

# Run job startup script and exit if there was an error
runJobStartup() {
    . /scripts/communicatingJobStartup.sh
    local exitCode=$?
    [ ${exitCode} -eq "${EXIT_CODE_WRITE_PERMISSION}" ] && exit "${EXIT_CODE_WRITE_PERMISSION}"
    [ ${exitCode} -ne 0 ] && exit 1
}

# Indicate that job is done and delete ssh keys and secret when script exits.
finish() {
    exitCode=${?}

    local secretName="$1"
    logger 4 "Deleting Kubernetes secret ${secretName} containing SSH keys"
    ${KUBECTL} delete secret "${secretName}" > /dev/null

    # Only indicate that the job is done if we are exiting this script with exit code 0
    if [ ${exitCode} -eq 0 ]; then
        indicateDone
    fi
    exit ${exitCode}
}

# Create a file to indicate that primary pod has finished.
indicateDone() {
    logger 4 "Primary worker execution complete"
    su "${PARALLEL_SERVER_USERNAME}" -c "touch ${PARALLEL_SERVER_STORAGE_LOCATION}/${PARALLEL_SERVER_JOB_LOCATION}.done"
}

# Copy own helm value inputs to a YAML file for input to secondary pods.
copyHelmValues() {
    ${HELM} get values "${HELM_RELEASE_NAME}" -o yaml > /scripts/secondary-communicating-job/values.yaml
}

# Get the name of the primary worker pod.
getPodName() {
    ${KUBECTL} get pods -l jobUID="${JOB_UID}" -o jsonpath='{.items[0].metadata.name}'
}

# Wait until the return of getPodIPs is non-empty.
waitForPrimaryIP() {
    logger 4 "Waiting for primary pod IP address"
    timeout 300 "${RUNCMD}" -c "while [ -z \$(${RUNCMD} /scripts/getPodIPs.sh) ]; do sleep 1; done"
    [ $? -eq 124 ] && logger 0 "Error: Timed out after ${TIMEOUT} seconds waiting for first pod IP address." && exit 124
}

# Install helm releases for secondary workers.
installSecondaryWorkers() {
    logger 4 "Installing helm releases for secondary workers"
    local secretName="$1"
    local primaryName
    primaryName=$(getPodName)
    local primaryIP
    primaryIP=$(${RUNCMD} /scripts/getPodIPs.sh)

    local helmOut
    for taskUID in $(getTaskUIDs); do
        logger 4 "Installing helm release: ${taskUID}"
        helmOut=$(${HELM} install "${taskUID}" /scripts/secondary-communicating-job \
            --set jobUID="${JOB_UID}" \
            --set taskUID="${taskUID}" \
            --set hostname="${primaryName}" \
            --set hostIP="${primaryIP}" \
            --set secretName="${secretName}" \
            --set containerJobStorageLocation="${PARALLEL_SERVER_STORAGE_LOCATION}" \
            --set containerMatlabRoot="${MATLAB_ROOT}")
        [ $? -ne 0 ] && logger 0 "${helmOut}"
    done
}

# Convert comma-separated list of task UIDs to space-separated list
getTaskUIDs() {
    echo "${TASK_UIDS}" | sed 's/,/ /g'
}

# Wait up to $TIMEOUT for all secondary pods to start running
waitForSecondaryWorkers() {
    timeout "${TIMEOUT}" "${RUNCMD}" /scripts/waitForRunningPods.sh
    if [ $? -eq 124 ]; then
        logger 0 "Error: Timed out after ${TIMEOUT} seconds waiting for ${NUMBER_OF_TASKS} pods to start running."
        uninstallSecondaryWorkers
        exit "${EXIT_CODE_TIMEOUT}"
    fi
}

# Uninstall secondary worker helm releases (used to clean up if there was a problem).
uninstallSecondaryWorkers() {
   logger 4 "Uninstalling helm releases for secondary workers"
    local helmOutput
   for taskUID in $(getTaskUIDs); do
       helmOutput=$(${HELM} uninstall "${taskUID}")
       [ $? -ne 0 ] && logger 0 "${helmOutput}"
   done
}

# Launch MPI ring between workers.
launchMpi() {
    # Replace spaces with commas to obtain format "ADDRESS1,ADDRESS2,...,ADDRESSN"
    local addresses
    addresses=$(${RUNCMD} /scripts/getPodIPs.sh | sed 's/ /,/g')

    local cmd="${MATLAB_ROOT}/bin/mw_mpiexec -hosts ${addresses} ${MATLAB_ROOT}/bin/worker ${PARALLEL_SERVER_MATLAB_ARGS} 2>&1"
    logger 4 "Running command: ${cmd}"
    su "${PARALLEL_SERVER_USERNAME}" -c "${cmd}" >> "${LOGFILE_FULL}"
    local exitCode=$?
    logger 0 "Exited MATLAB with code: ${exitCode}"
}

# Write log entry
logger() {
    local level="$1"
    local message="$2"
    ${RUNCMD} /scripts/logger.sh "${level}" "primaryWorker.sh" "${message}"
}

main
