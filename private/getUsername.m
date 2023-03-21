function username = getUsername()
% Get name of current user from system.

% Copyright 2022-2023 The MathWorks, Inc.
if ispc
    username = getenv("username");
else
    username = getenv("USER");
end
if isempty(username)
    username = 'matlab';
end
end
