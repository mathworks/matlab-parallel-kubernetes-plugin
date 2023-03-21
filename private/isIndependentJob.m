function tf = isIndependentJob(job)
% Return true if a job is a communicating job.

% Copyright 2023 The MathWorks, Inc.
tf = strcmp(job.Type, 'independent');
end
