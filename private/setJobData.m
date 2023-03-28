function setJobData(cluster, job, jobUID, releaseName, podNames)
% Store data for a job.
% The job's UID and associated helm release name are saved to the cluster's
% job data.
% The name of each pod is set to the schedulerID of the task corresponding to
% that pod.

% Copyright 2022-2023 The MathWorks, Inc.
insertJobData(cluster, job, "HelmRelease", releaseName);
insertJobData(cluster, job, "JobUID", jobUID);
insertJobData(cluster, job, "HelmUninstalled", false);
insertJobData(cluster, job, "Errors", {});

set(job.Tasks, 'SchedulerID', podNames);
end
