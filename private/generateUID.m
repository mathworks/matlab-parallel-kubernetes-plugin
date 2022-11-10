function id = generateUID()
% Generate unique ID and replace underscores with dashes so the UID can be
% used as part of a Helm release name.

% Copyright 2022 The MathWorks, Inc.

[~, id] = fileparts(tempname);
id = replace(id, "_", "-");

% First two chars of tempname are always "tp", so trim these off
id = id(3:end);
end
