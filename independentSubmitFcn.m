function independentSubmitFcn(cluster, job, environmentProperties)
% Submit independent MATLAB job to a Kubernetes cluster.

% Copyright 2022 The MathWorks, Inc.

checkExecutables();
checkClusterProperties(cluster);
iCheckResourceQuotas(cluster, job);

jobUID = generateUID();
[releaseName, podNames] = createResourceNames(environmentProperties, job, jobUID);

iSubmitJob(releaseName, jobUID, podNames, cluster, job, environmentProperties);

setJobData(cluster, job, jobUID, releaseName, podNames);

end

function iCheckResourceQuotas(cluster, job)
% Check that the NumThreads requested for this job does not exceed the
% cluster's CPU resource quota
[~, nCPUs] = getResourceQuotas(cluster, job);
namespace = cluster.getJobClusterData(job).Namespace;
if cluster.NumThreads > nCPUs
    error('parallelexamples:GenericKubernetes:NumThreadsExceedsCPUQuota', ...
        'Job requires %d CPUs (NumThreads), but the namespace "%s" has a CPU quota of %d.', ...
        cluster.NumThreads, namespace, nCPUs);
end
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
