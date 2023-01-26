function postConstructFcn(cluster)
% Runs after construction of a cluster object.

% Copyright 2022 The MathWorks, Inc.
if ~isprop(cluster.AdditionalProperties, 'ClientConnectsToWorkers')
    cluster.AdditionalProperties.ClientConnectsToWorkers = false;
end
end
