function [nPods, nCPUs] = getResourceQuotas(cluster, job)
% Get the maximum number of pods and CPUs that can run in the cluster's
% namespace.
%
% Copyright 2022 The MathWorks, Inc.
[~, rawJson] = runKubeCmd('kubectl get resourcequotas -o json', cluster, job);
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
