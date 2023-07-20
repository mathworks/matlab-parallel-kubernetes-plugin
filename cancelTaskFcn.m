function ok = cancelTaskFcn(cluster, task)
% Cancel a task submitted to a Kubernetes cluster.

% Copyright 2022-2023 The MathWorks, Inc.

% We can't cancel a single task of a communicating job on the scheduler
% without cancelling the entire job, so warn and return in this case
if ~strcmpi(task.Parent.Type, 'independent')
    ok = false;
    warning('parallelexamples:GenericKubernetes:FailedToCancelTask', ...
        'Unable to cancel a single task of a communicating job. If you want to cancel the entire job, use the cancel function on the job object instead.');
    return
end

% For independent jobs, delete the kubernetes job corresponding to the task
commandToRun = "kubectl delete job -l taskUID=" + task.SchedulerID;
[exitCode, result] = runKubeCmd(commandToRun, cluster, false);
ok = exitCode == 0;
if ~ok
    warning("parallelexamples:GenericKubernetes:HelmUninstallFailed", ...
        "Failed to uninstall Helm release: %s", result);
end
end
