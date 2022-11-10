function timeout = getTimeout(cluster)
% Get timeout in seconds to use when waiting for all communicating job workers to
% start after the first worker has started.

%   Copyright 2022 The MathWorks, Inc.

if isprop(cluster.AdditionalProperties, 'Timeout')
    timeout = cluster.AdditionalProperties.Timeout;
else
    timeout = 600;  % Default timeout in seconds
end
