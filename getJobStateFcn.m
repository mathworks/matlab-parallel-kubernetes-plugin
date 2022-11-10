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

clusterState = iExtractJobState(podInfo, numel(job.Tasks));

% If we could determine the cluster's state, we'll use that, otherwise
% stick with MATLAB's job state.
if ~strcmp(clusterState, 'unknown')
    state = clusterState;
end
end

function state = iExtractJobState(podInfo, numTasks)
% Extract the job state from the output of kubectl.
% See https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase for pod phases

numPending  = 0;
numRunning  = 0;
numFinished = 0;
numFailed   = 0;

for idx = 1:numel(podInfo.items)
    if strcmp(podInfo.items(idx).status.phase, "Pending")
        numPending = numPending + 1;
    elseif strcmp(podInfo.items(idx).status.phase, 'Running')
        numRunning = numRunning + 1;
    elseif strcmp(podInfo.items(idx).status.phase, 'Succeeded')
        numFinished = numFinished + 1;
    elseif strcmp(podInfo.items(idx).status.phase, 'Failed')
        numFailed = numFailed + 1;
    end
end

% If pods for all tasks have finished, the job is finished
if numFinished == numTasks
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
    return
end

state = 'unknown';
end
