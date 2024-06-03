function deleteJobFcn(cluster, job)
% Delete a job submitted to a Kubernetes cluster.

% Copyright 2022-2023 The MathWorks, Inc.

cancelJobOnCluster(cluster, job);

end
