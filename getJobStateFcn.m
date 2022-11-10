function state = getJobStateFcn(cluster, job, state)
% Query the state of a job on a Kubernetes cluster.

% Copyright 2022 The MathWorks, Inc.

if strcmp(state, "finished") || strcmp(state, "failed")
    return
end

data = cluster.getJobClusterData(job);
if ~isfield(data, 'JobUID')
    return
end
jobUID = data.JobUID;

commandToRun = sprintf("kubectl get pod -l jobUID=""%s"" -o json", jobUID);
[~, cmdOut] = runKubeCmd(commandToRun, cluster, job);
podInfo = jsondecode(cmdOut);

clusterState = iExtractJobState(podInfo, job);

% If we could determine the cluster's state, we'll use that, otherwise
% stick with MATLAB's job state.
if ~strcmp(clusterState, 'unknown')
    state = clusterState;
end
end

function state = iExtractJobState(podInfo, job)
% Extract the job state from the output of kubectl.
% See https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase for pod phases

numPending  = 0;
numRunning  = 0;
numFinished = 0;
numFailed   = 0;

failedPods = {};
for idx = 1:numel(podInfo.items)
    if strcmp(podInfo.items(idx).status.phase, "Pending")
        numPending = numPending + 1;
    elseif strcmp(podInfo.items(idx).status.phase, 'Running')
        numRunning = numRunning + 1;
    elseif strcmp(podInfo.items(idx).status.phase, 'Succeeded')
        numFinished = numFinished + 1;
    elseif strcmp(podInfo.items(idx).status.phase, 'Failed')
        numFailed = numFailed + 1;
        failedPods{end + 1} = podInfo.items(idx); %#ok<AGROW>
    end
end

% If pods for all tasks have finished, the job is finished
if numFinished == numel(job.Tasks)
    state = 'finished';
    return
end

% Any running indicates that the job is running
if numRunning > 0
    state = 'running';
    return
end

% We know numRunning == 0 so if there are some still pending then the
% job must be queued again, even if there are some finished
if numPending > 0
    state = 'queued';
    return
end

% Deal with any tasks that have failed
if numFailed > 0
    % Set this job to be failed
    state = 'failed';
    iCheckExitCode(failedPods, job);
    return
end

state = 'unknown';
end

function iCheckExitCode(failedPods, job)
% Throw an error if a known exit code was returned by the first failed pod.
% Exit codes:
%    2: Worker does not have write permission for the job storage
%       location.
%    3: Communicating job timed out waiting for all worker pods to start.
exitCode = failedPods{1}.status.containerStatuses.state.terminated.exitCode;

cluster = job.Parent;
if exitCode == 2
    iError(job, 'parallelexamples:GenericKubernetes:NoWritePermissionOnCluster', ...
        sprintf('Worker with user ID = %d, group ID = %d does not have permission to write to the job storage location on the cluster (%s).', ...
        cluster.AdditionalProperties.ClusterUserID, ...
        cluster.AdditionalProperties.ClusterGroupID, ...
        cluster.AdditionalProperties.ClusterJobStorageLocation));
elseif exitCode == 3 && iIsCommunicatingJob(job)
    iError(job, 'parallelexamples:GenericKubernetes:CommunicatingJobTimeout', ...
        sprintf('Job timed out after %d seconds waiting for %d workers to start. Submit a job with fewer workers or increase the timeout by editing the cluster''s "Timeout" additional property.', ...
        getTimeout(cluster), max(job.NumWorkersRange)));
end
end

function iError(job, errId, message)
% Throw an error if this error has not been thrown before for this job.
cluster = job.Parent;
previousErrors = cluster.getJobClusterData(job).Errors;
if ~any(strcmp(errId, previousErrors))
    previousErrors{end + 1} = errId;
    insertJobData(cluster, job, "Errors", previousErrors);
    error(errId, message);
end
end

function isCommunicatingJob = iIsCommunicatingJob(job)
communicatingJobTypes = ["pool", "spmd", "concurrent"];
isCommunicatingJob = any(strcmp(job.Type, communicatingJobTypes));
end
