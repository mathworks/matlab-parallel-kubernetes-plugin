function cmd = appendHelmSetting(cmd, name, val, isArray)
% Append '--set name="val"' to a command. If 'isArray' is set, parse 'val' into
% the format {item1,item2,...}

% Copyright 2022 The MathWorks, Inc.
if nargin < 4
    isArray = false;
end
val = string(val);
if isArray
    valStr = sprintf("{%s}", strjoin(val, ","));
else
    valStr = val;
end
cmd = sprintf("%s --set %s=""%s""", cmd, name, valStr);
end
