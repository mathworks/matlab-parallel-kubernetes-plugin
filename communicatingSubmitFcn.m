function communicatingSubmitFcn(cluster, job, environmentProperties)
% Submit communicating MATLAB job to a Kubernetes cluster.

% Copyright 2022 The MathWorks, Inc.

checkExecutables();
checkClusterProperties(cluster);

% Generate helm release name for each task
jobUID = generateUID();
[releaseName, podNames] = createResourceNames(environmentProperties, job, jobUID);

iSubmitToPrimaryWorker(releaseName, jobUID, podNames, cluster, job, environmentProperties);
setJobData(cluster, job, jobUID, podNames, podNames);
end

function iSubmitToPrimaryWorker(releaseName, jobUID, podNames, cluster, job, environmentProperties)
% Submit job to primary pod; this pod will asynchronously launch all other
% workers.

cmd = createBaseHelmInstallCommand(...
    releaseName, ...
    jobUID, ...
    podNames, ...
    fullfile(cluster.PluginScriptsLocation, "communicating-job"), ...
    cluster, environmentProperties);

cmd = appendHelmSetting(cmd, "parallelServer.decodeFunction", ...
    "parallel.cluster.generic.communicatingDecodeFcn");
cmd = appendHelmSetting(cmd, "numberOfTasks", ...
    environmentProperties.NumberOfTasks);
cmd = appendHelmSetting(cmd, "serviceAccountName", ...
    lower(sprintf("%s-serviceaccount-%s", releaseName, jobUID)));
cmd = appendHelmSetting(cmd, "logfile", getRelativeLogLocation(cluster, job));
cmd = appendHelmSetting(cmd, "timeout", getTimeout(cluster));

cmd = appendOptionalHelmSetting(cmd, cluster, "HelmDir", "clusterHelmDir");
cmd = appendOptionalHelmSetting(cmd, cluster, "KubectlDir", "clusterKubectlDir");

if cluster.RequiresOnlineLicensing
    cmd = applyOnlineLicensingSettings(cmd, cluster, job, jobUID, ...
        environmentProperties);
end

runKubeCmd(cmd, cluster, job);
end
