function checkExecutables()
% Check for helm and kubectl executables on the system. If either is not
% present, throw an error.

% Copyright 2022 The MathWorks, Inc.

executables = ["kubectl", "helm"];
for ex = executables
    [exitCode, ~] = system("which " + ex);
    if exitCode ~= 0
        error("parallelexamples:GenericKubernetes:MissingExecutable", ...
            "%s executable not found", ex);
    end
end
end
