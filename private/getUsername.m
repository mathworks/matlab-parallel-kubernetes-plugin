function username = getUsername()
% Get name of current user from system.

% Copyright 2022 The MathWorks, Inc.
if ispc
    username = getenv("username");
else
    username = getenv("USER");
end
end
