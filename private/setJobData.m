function setJobData(cluster, job, jobUID, releaseNames, podNames)
% Store data for a job.
% The job's UID and associated helm release name(s) are saved to the cluster's
% job data.
% The name of each pod is set to the schedulerID of the task corresponding to
% that pod.

% Copyright 2022 The MathWorks, Inc.
insertJobData(cluster, job, "HelmReleases", releaseNames);
insertJobData(cluster, job, "JobUID", jobUID);
insertJobData(cluster, job, "HelmUninstalled", false);
insertJobData(cluster, job, "Errors", {});

set(job.Tasks, 'SchedulerID', podNames);
end
