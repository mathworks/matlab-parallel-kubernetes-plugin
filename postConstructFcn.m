function postConstructFcn(cluster)
% Runs after construction of a cluster object.

% Copyright 2022-2023 The MathWorks, Inc.
checkClusterProperties(cluster);

if ~isprop(cluster.AdditionalProperties, 'ClientConnectsToWorkers')
    cluster.AdditionalProperties.ClientConnectsToWorkers = false;
end

% Derive the matlabroot in the worker containers
% If using a MATLAB installation in a PersistentVolume, this will be
% mounted at /matlab on the containers
if isprop(cluster.AdditionalProperties, 'MatlabPVC')
    cluster.ClusterMatlabRoot = fullfile('/matlab', cluster.AdditionalProperties.MatlabPath);
else
    % Otherwise, MATLAB should be installed on the image at /matlab
    cluster.ClusterMatlabRoot = '/matlab';
end
end
