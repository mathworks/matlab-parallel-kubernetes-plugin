function ok = cancelJobFcn(cluster, job)
% Cancel a job submitted to a Kubernetes cluster by uninstalling all helm
% releases associated with the job.

% Copyright 2022-2023 The MathWorks, Inc.

if cluster.getJobClusterData(job).HelmUninstalled
    ok = true;
    return
end

releases = cluster.getJobClusterData(job).HelmRelease;

% If a communicating job is not yet running or finished, the helm releases
% for secondary workers may not have been created yet, so don't warn if
% these releases cannot be uninstalled
warnIfFailed = true(size(releases));
if ~strcmpi(job.Type, 'independent') && strcmp(job.Tasks(1).State, 'pending')
    warnIfFailed(2:end) = false;
end

exitCodes = arrayfun(@(idx) iUninstallRelease(cluster, job, releases(idx), warnIfFailed(idx)), ...
    1:numel(releases));

if cluster.RequiresOnlineLicensing
    iDeleteUserCredSecret(cluster, job);
end

ok = all(exitCodes(warnIfFailed) == 0);
if ok
    iSetUninstalledFlag(cluster, job, true);
end
end

function iSetUninstalledFlag(cluster, job, flag)
data = cluster.getJobClusterData(job);
data.HelmUninstalled = flag;
cluster.setJobClusterData(job, data);
end

function exitCode = iUninstallRelease(cluster, job, release, warnIfFailed)
commandToRun = "helm uninstall " + release;
[exitCode, result] = runKubeCmd(commandToRun, cluster, job, false);
if exitCode ~= 0 && warnIfFailed
    warning("parallelexamples:GenericKubernetes:HelmUninstallFailed", ...
        "Failed to uninstall Helm release: %s", result);
end
end

function exitCode = iDeleteUserCredSecret(cluster, job)
secretName = cluster.getJobClusterData(job).UserCredSecret;
commandToRun = "kubectl delete secret " + secretName;
exitCode = runKubeCmd(commandToRun, cluster, job, false);
end
