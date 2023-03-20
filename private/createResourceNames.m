function [helmReleaseName, podNames] = createResourceNames(environmentProperties, jobUID)
% Create unique Helm release name and names for the Kubernetes pods corresponding
% to each task/worker in a job. Each name will conform with Helm's naming standards
% (lowercase, <= 53 characters).
%
% For independent jobs, the Helm release name corresponds to the entire job.
% For communicating jobs, each worker has a separate Helm release, so return
% the release name for the primary pod.

% Copyright 2022-2023 The MathWorks, Inc.

username = getUsername();
jobName = environmentProperties.JobLocation;
nTasks = environmentProperties.NumberOfTasks;

podSuffixes = arrayfun(@(n) sprintf("-%s-%d-%s", jobName, n, jobUID), 1:nTasks);
podNames = arrayfun(@(name) iConformWithHelmNamingStandards(username, name), podSuffixes);

helmReleaseSuffix = sprintf("-%s-%s", jobName, jobUID);
helmReleaseName = iConformWithHelmNamingStandards(username, helmReleaseSuffix);
end

function name = iConformWithHelmNamingStandards(username, suffix)
% Combine username and suffix to create a name that conforms with Helm's
% naming standards. If the name will be too long, truncate the username.

maxLen = 53;
suffixLen = strlength(suffix);
if strlength(username) + suffixLen > maxLen
    username = username(1:maxLen - suffixLen);
end
name = sprintf("%s%s", username, suffix);
name = lower(name);
end
