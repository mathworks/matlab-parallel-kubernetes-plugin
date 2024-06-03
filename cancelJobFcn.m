function ok = cancelJobFcn(cluster, job)
% Cancel a job submitted to a Kubernetes cluster.

% Copyright 2022-2023 The MathWorks, Inc.

ok = cancelJobOnCluster(cluster, job);

end
