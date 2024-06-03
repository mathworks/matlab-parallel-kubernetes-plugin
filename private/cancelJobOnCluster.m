function ok = cancelJobOnCluster(cluster, job)
% Cancel a job on the Kubernetes cluster by uninstalling the helm
% release associated with the job.

% Copyright 2022-2023 The MathWorks, Inc.

if cluster.getJobClusterData(job).HelmUninstalled
    ok = true;
    return
end

release = cluster.getJobClusterData(job).HelmRelease;
exitCode = iUninstallRelease(cluster, release);

if cluster.RequiresOnlineLicensing
    iDeleteUserCredSecret(cluster, job);
end

ok = exitCode == 0;
if ok
    iSetUninstalledFlag(cluster, job, true);
end
end

function iSetUninstalledFlag(cluster, job, flag)
data = cluster.getJobClusterData(job);
data.HelmUninstalled = flag;
cluster.setJobClusterData(job, data);
end

function exitCode = iUninstallRelease(cluster, release)
commandToRun = "helm uninstall " + release;
[exitCode, result] = runKubeCmd(commandToRun, cluster, false);
if exitCode ~= 0
    warning("parallelexamples:GenericKubernetes:HelmUninstallFailed", ...
        "Failed to uninstall Helm release: %s", result);
end
end

function exitCode = iDeleteUserCredSecret(cluster, job)
secretName = cluster.getJobClusterData(job).UserCredSecret;
commandToRun = "kubectl delete secret " + secretName;
exitCode = runKubeCmd(commandToRun, cluster, false);
end
