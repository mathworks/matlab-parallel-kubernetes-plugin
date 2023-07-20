function logfile = getRelativeLogLocation(cluster, taskOrJob)
% Get a the log location relative to a cluster's job storage location for a
% task (independent jobs only) or job (communicating jobs only).

%   Copyright 2022-2023 The MathWorks, Inc.

jobStorageLoc = cluster.JobStorageLocation;
if isstruct(jobStorageLoc)
    if ispc
        jobStorageLoc = jobStorageLoc.windows;
    else
        jobStorageLoc = jobStorageLoc.unix;
    end
end

logfile = extractAfter(cluster.getLogLocation(taskOrJob), ...
    strlength(fullfile(jobStorageLoc)));

% The workers run on Linux, so relative logfile needs to be a Linux path
logfile = strrep(logfile, "\", "/");
end
