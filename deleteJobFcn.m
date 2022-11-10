function deleteJobFcn(cluster, job)
% Delete a job submitted to a Kubernetes cluster.

% Copyright 2022 The MathWorks, Inc.

cancelJobFcn(cluster, job);

end
