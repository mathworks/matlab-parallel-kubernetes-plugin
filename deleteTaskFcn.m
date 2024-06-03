function deleteTaskFcn(cluster, task)
% Delete a task submitted to a Kubernetes cluster.

% Copyright 2022-2023 The MathWorks, Inc.

cancelTaskOnCluster(cluster, task);

end
