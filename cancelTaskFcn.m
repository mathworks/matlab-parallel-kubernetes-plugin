function ok = cancelTaskFcn(cluster, task)
% Cancel a task submitted to a Kubernetes cluster.

% Copyright 2022-2023 The MathWorks, Inc.

ok = cancelTaskOnCluster(cluster, task);

end
