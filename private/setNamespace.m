function setNamespace(cluster, job)
% Choose the kubernetes namespace that should be used by a cluster, ensure
% that it exists, and store it in the job cluster data. The namespace is chosen as follows:
% 1. If the cluster already has a namespace set in its additional properties, use that;
% 2. If not, try to create namespace "matlab" and use that;
% 3. Otherwise, use the "default" namespace.

% Copyright 2022 The MathWorks, Inc.

if isprop(cluster.AdditionalProperties, "Namespace")
    namespace = cluster.AdditionalProperties.Namespace;
else
    namespace = "matlab";
end

insertJobData(cluster, job, "Namespace", namespace);
ok = iEnsureNamespaceExists(cluster, job, namespace);
if ~ok
    insertJobData(cluster, job, "Namespace", "default");
end
end

function ok = iEnsureNamespaceExists(cluster, job, namespace)
% Check whether a kubernetes namespace exists and attempt to create it if not.

ok = true;
try
    cmd = sprintf("kubectl get namespace %s -o json", namespace);
    runKubeCmd(cmd, cluster, job);
catch
    try
        cmd = "kubectl create namespace " + namespace;
        dctSchedulerMessage(4, "Creating kubernetes namespace ""%s""\n", namespace);
        runKubeCmd(cmd, cluster, job);
    catch
        ok = false;
    end
end
end
