function [nPods, nCPUs] = getResourceQuotas(cluster, job)
% Get the maximum number of pods and CPUs that can run in the cluster's
% namespace
[~, rawJson] = runKubeCmd('kubectl get resourcequotas -o json', cluster, job);
quotas = jsondecode(rawJson);

nPods = Inf;
nCPUs = Inf;

for idx = 1:numel(quotas.items)
    quota = quotas.items(idx);
    if isfield(quota.spec, 'hard')
        if isfield(quota.spec.hard.pods)
            nPods = min([pods nPods]);
        end
        if isfield(quota.spec.hard, 'cpu')
            nCPUs = min([nPods nCPUs]);
        end
    end
end
end