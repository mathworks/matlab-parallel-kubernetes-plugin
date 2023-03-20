function independentSubmitFcn(cluster, job, environmentProperties)
% Submit independent MATLAB job to a Kubernetes cluster.

% Copyright 2022-2023 The MathWorks, Inc.
preSubmitChecks(cluster, job, environmentProperties);

jobUID = generateUID();
[releaseName, podNames] = createResourceNames(environmentProperties, jobUID);

iSubmitJob(releaseName, jobUID, podNames, cluster, job, environmentProperties);
setJobData(cluster, job, jobUID, releaseName, podNames);
end

function iSubmitJob(releaseName, jobUID, podNames, cluster, job, environmentProperties)

% Get tasks to submit; cancelled tasks will have errors and should not be submitted
isPending = arrayfun(@(t) isempty(t.Error), job.Tasks);
podNames = podNames(isPending);
taskLocs = environmentProperties.TaskLocations(isPending);
taskLogs = arrayfun(@(t) getRelativeLogLocation(cluster, t), job.Tasks(isPending));

cmd = createBaseHelmInstallCommand(...
    releaseName, ...
    jobUID, ...
    podNames, ...
    fullfile(cluster.PluginScriptsLocation, "independent-job"), ...
    cluster, ...
    environmentProperties);

cmd = appendHelmSetting(cmd, "parallelServer.decodeFunction", ...
    "parallel.cluster.generic.independentDecodeFcn");

cmd = appendHelmSetting(cmd, "parallelServer.taskLocations", taskLocs, true);
cmd = appendHelmSetting(cmd, "taskLogs", taskLogs, true);

if cluster.RequiresOnlineLicensing
    cmd = applyOnlineLicensingSettings(cmd, cluster, job, jobUID, ...
        environmentProperties);
end

runKubeCmd(cmd, cluster, job);
end
