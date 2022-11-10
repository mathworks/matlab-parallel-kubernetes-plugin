function deleteTaskFcn(cluster, task)
% Delete a task submitted to a Kubernetes cluster.

% Copyright 2022 The MathWorks, Inc.

cancelTaskFcn(cluster, task);

end
