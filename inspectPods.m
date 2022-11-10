function out = inspectPods(obj)
% Display information for Kubernetes pod(s) corresponding to a job or task.
%
% inspectPods(job) will display an overview of pods corresponding to that
% job.
%
% inspectPods(task) will display details for the single pod corresponding
% to that task.
%
% out = inspectPods(obj) will return the output as a string.
%

% Copyright 2022 The MathWorks, Inc.

mustBeA(obj, {'parallel.job.CJSIndependentJob', ...
    'parallel.job.CJSCommunicatingJob', ...
    'parallel.task.CJSTask'});

isTask = isa(obj, 'parallel.task.CJSTask');
if isTask
    job = obj.Parent;
else
    job = obj;
end

if strcmp(job.State, 'pending')
    return
end

cluster = job.Parent;

if isTask
    commandToRun = "kubectl describe pods -l taskUID=" + obj.SchedulerID;
else
    jobUID = cluster.getJobClusterData(job).JobUID;
    commandToRun = "kubectl get pods -l jobUID=" + jobUID;
end

[~, cmdOut] = runKubeCmd(commandToRun, cluster, job);

if isTask
    cmdOut = iAppendKubernetesLogs(cmdOut, cluster, job, obj);
end

if nargout == 1
    out = cmdOut;
else
    disp(cmdOut);
end
end

function str = iAppendKubernetesLogs(str, cluster, job, task)
% Append a string with the Kubernetes logs for a task's pod if the pod has
% started running

podData = iGetPodData(cluster, job, task);
if numel(podData.items) == 0
    return
end

podName = podData.items(1).metadata.name;
podStatus = podData.items(1).status.phase;
if strcmp(podStatus, 'Pending')
    return
end

[~, logs] = runKubeCmd("kubectl logs " + podName, cluster, job);
str = sprintf("%s\n\nLogs:\n%s", str, logs);
end

function podData = iGetPodData(cluster, job, task)
% Get struct containing data for a task's Kubernetes pod

commandToRun = "kubectl get pods -o json -l taskUID=" + task.SchedulerID;
[~, podJsonRaw] = runKubeCmd(commandToRun, cluster, job);
podData = jsondecode(podJsonRaw);
end
