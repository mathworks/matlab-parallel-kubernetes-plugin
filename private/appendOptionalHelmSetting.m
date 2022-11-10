function cmd = appendOptionalHelmSetting(cmd, cluster, propName, helmName)
% Append a cluster's additional property to a helm command if it has that property.

% Copyright 2022 The MathWorks, Inc.

if isprop(cluster.AdditionalProperties, propName)
    cmd = appendHelmSetting(cmd, helmName, cluster.AdditionalProperties.(propName));
end
end
