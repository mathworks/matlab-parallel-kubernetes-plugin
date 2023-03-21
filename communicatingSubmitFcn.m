function communicatingSubmitFcn(cluster, job, environmentProperties)
% Submit communicating MATLAB job to a Kubernetes cluster.

% Copyright 2022-2023 The MathWorks, Inc.

preSubmitChecks(cluster, job, environmentProperties);

jobUID = generateUID();
[releaseName, podNames] = createResourceNames(environmentProperties, jobUID);

iSubmitJob(releaseName, jobUID, podNames, cluster, job, environmentProperties);
setJobData(cluster, job, jobUID, releaseName, podNames);
end

function iSubmitJob(releaseName, jobUID, podNames, cluster, job, environmentProperties)

cmd = createBaseHelmInstallCommand(...
    releaseName, ...
    jobUID, ...
    podNames, ...
    fullfile(cluster.PluginScriptsLocation, "communicating-job"), ...
    cluster, environmentProperties);

cmd = appendHelmSetting(cmd, "parallelServer.decodeFunction", ...
    "parallel.cluster.generic.communicatingDecodeFcn");
cmd = appendHelmSetting(cmd, "parallelServer.taskLocations", ...
    environmentProperties.TaskLocations, true);
cmd = appendHelmSetting(cmd, "logfile", getRelativeLogLocation(cluster, job));
cmd = appendHelmSetting(cmd, "timeout", getTimeout(cluster));

runKubeCmd(cmd, cluster, job);
end
