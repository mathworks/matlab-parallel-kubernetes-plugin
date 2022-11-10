function [helmReleaseName, podNames] = createResourceNames(environmentProperties, job, jobUID)
% Create unique Helm release name and names for the Kubernetes pods corresponding
% to each task/worker in a job. Each name will conform with Helm's naming standards
% (lowercase, <= 53 characters).
%
% For independent jobs, the Helm release name corresponds to the entire job.
% For communicating jobs, each worker has a separate Helm release, so return
% the release name for the primary pod.

% Copyright 2022 The MathWorks, Inc.

username = getUsername();
jobName = environmentProperties.JobLocation;
nTasks = environmentProperties.NumberOfTasks;

podNames = arrayfun(@(n) sprintf("%s-%s-%d-%s", username, jobName, n, jobUID), 1:nTasks);
podNames = arrayfun(@(name) iConformWithHelmNamingStandards(name), podNames);

if strcmp(job.Type, 'independent')
    helmReleaseName = sprintf("%s-%s-%s", username, jobName, jobUID);
    helmReleaseName = iConformWithHelmNamingStandards(helmReleaseName);
else
    helmReleaseName = podNames(1);
end
end

function name = iConformWithHelmNamingStandards(name)
% Format a name to conform with Helm's naming standards

name = lower(name);
if strlength(name) > 53
    name = name(1:53);
end
end
