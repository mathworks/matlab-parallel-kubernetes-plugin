function logfile = getRelativeLogLocation(cluster, taskOrJob)
% Get a the log location relative to a cluster's job storage location for a
% task (independent jobs only) or job (communicating jobs only).

%   Copyright 2022 The MathWorks, Inc.

logfile = extractAfter(cluster.getLogLocation(taskOrJob), ...
    strlength(fullfile(cluster.JobStorageLocation)));
logfile = string(logfile);
end
