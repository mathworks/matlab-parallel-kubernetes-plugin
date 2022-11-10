function ok = cancelJobFcn(cluster, job)
% Cancel a job submitted to a Kubernetes cluster by uninstalling all helm
% releases associated with the job.

% Copyright 2022 The MathWorks, Inc.

if cluster.getJobClusterData(job).HelmUninstalled
    ok = true;
    return
end

releases = cluster.getJobClusterData(job).HelmReleases;

% If the first task of a communicating job has not yet run, subsequent releases
% will not yet have been created, so we should only delete the first release
if ~strcmpi(job.Type, 'independent') && strcmp(job.Tasks(1).State, 'pending')
    releases = releases(1);
end

exitCodes = arrayfun(@(release) iUninstallRelease(cluster, job, release), releases);

if cluster.RequiresOnlineLicensing
    iDeleteUserCredSecret(cluster, job);
end

ok = all(exitCodes == 0);
if ok
    iSetUninstalledFlag(cluster, job, true);
end
end

function iSetUninstalledFlag(cluster, job, flag)
data = cluster.getJobClusterData(job);
data.HelmUninstalled = flag;
cluster.setJobClusterData(job, data);
end

function exitCode = iUninstallRelease(cluster, job, release)
commandToRun = "helm uninstall " + release;
exitCode = runKubeCmd(commandToRun, cluster, job, false);
end

function exitCode = iDeleteUserCredSecret(cluster, job)
secretName = cluster.getJobClusterData(job).UserCredSecret;
commandToRun = "kubectl delete secret " + secretName;
exitCode = runKubeCmd(commandToRun, cluster, job, false);
end
