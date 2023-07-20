function preSubmitChecks(cluster, job, environmentProperties)
% Check that this cluster is able to run the job.

% Copyright 2023 The MathWorks, Inc.

iCheckExecutables();
checkClusterProperties(cluster);
iCheckResourceQuotas(cluster, job, environmentProperties);
end

function iCheckExecutables()
% Check for helm and kubectl executables on the system. If either is not
% present, throw an error.
executables = ["kubectl", "helm"];
for ex = executables
    [exitCode, ~] = system(ex + " help");
    if exitCode ~= 0
        error("parallelexamples:GenericKubernetes:MissingExecutable", ...
            "%s executable not found", ex);
    end
end
end

function iCheckResourceQuotas(cluster, job, environmentProperties)
% Check that the resources requested for this job do not exceed the
% cluster's pod or CPU resource quotas
[nPods, nCPUs] = iGetResourceQuotas(cluster);
namespace = cluster.AdditionalProperties.Namespace;

if ~isIndependentJob(job)
    requestedCPUs = environmentProperties.NumberOfTasks * cluster.NumThreads;
else
    requestedCPUs = cluster.NumThreads;
end
if requestedCPUs > nCPUs
    error('parallelexamples:GenericKubernetes:JobExceedsCPUQuota', ...
        'Job requires %d CPUs, but the namespace "%s" has a CPU quota of %d.', ...
        requestedCPUs, namespace, nCPUs);
end

if ~isIndependentJob(job)
    requestedWorkers = environmentProperties.NumberOfTasks;
    if requestedWorkers > nPods
        error('parallelexamples:GenericKubernetes:NumWorkersExceedsPodQuota', ...
            'Job requires %d workers, but the namespace "%s" has a pod quota of %d.', ...
            requestedWorkers, namespace, nPods);
    end
end
end

function [nPods, nCPUs] = iGetResourceQuotas(cluster)
% Get the maximum number of pods and CPUs that can run in the cluster's
% namespace.
[~, rawJson] = runKubeCmd('kubectl get resourcequotas -o json', cluster);
quotas = jsondecode(rawJson);

nPods = Inf;
nCPUs = Inf;

for idx = 1:numel(quotas.items)
    quota = quotas.items(idx);
    if isfield(quota.spec, 'hard')
        if isfield(quota.spec.hard, 'pods')
            podQuota = str2double(quota.spec.hard.pods);
            nPods = min([podQuota nPods]);
        end
        if isfield(quota.spec.hard, 'cpu')
            cpuQuota = str2double(quota.spec.hard.cpu);
            nCPUs = min([cpuQuota nCPUs]);
        end
    end
end
end
