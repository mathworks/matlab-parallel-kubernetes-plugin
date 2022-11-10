function insertJobData(cluster, job, name, value)
% Insert a field into a job's cluster data

% Copyright 2022 The MathWorks, Inc.
data = cluster.getJobClusterData(job);
data.(name) = value;
cluster.setJobClusterData(job, data);
end
