function checkClusterProperties(cluster)
% Check that a cluster has the required properties and that its properties
% are of the correct data type.

% Copyright 2022-2023 The MathWorks, Inc.

iCheckRequiredAdditionalProperties(cluster);
iCheckOptionalAdditionalProperties(cluster);
end

function iCheckRequiredAdditionalProperties(cluster)
% Check cluster has required properties and that they are of the correct type;
% throw an error if properties are missing or type mismatches are found.

iCheckCharOrString(cluster, "Image");
iCheckCharOrString(cluster, "ImagePullPolicy");
iCheckCharOrString(cluster, "Namespace");
iCheckCharOrString(cluster, "JobStoragePVC");
iCheckCharOrString(cluster, "JobStoragePath");
iCheckInt(cluster, "ClusterUserID");
iCheckInt(cluster, "ClusterGroupID");
end

function iCheckOptionalAdditionalProperties(cluster)
% Check cluster's additional properties are of the correct type; throw an error
% if type mismatches are found.

iCheckOptional(cluster, "JobStorageServer", @iCheckCharOrString);
iCheckOptional(cluster, "KubeConfig", @iCheckCharOrString);
iCheckOptional(cluster, "KubeContext", @iCheckCharOrString);
iCheckOptional(cluster, "Timeout", @iCheckInt);
iCheckOptional(cluster, "MatlabPVC", @iCheckCharOrString);
iCheckOptional(cluster, "MatlabPath", @iCheckCharOrString);
iCheckOptional(cluster, "LicenseServer", @iCheckCharOrString);

iCheckDependentProp(cluster, 'MatlabPVC', 'MatlabPath');
end

function iCheckHasProp(cluster, name)
% Check whether cluster has property "name" in its AdditionalProperties;
% if not, throw an error.
if ~isprop(cluster.AdditionalProperties, name)
    error("parallelexamples:GenericKubernetes:MissingAdditionalProperties", ...
        "Required field %s is missing from AdditionalProperties.", name)
end
end

function iCheckCharOrString(cluster, name)
% Throw an error if cluster.AdditionalProperties.(name) is not a char or string.
iCheckHasProp(cluster, name);
object = cluster.AdditionalProperties.(name);
if ~(ischar(object) || isstring(object))
    error("parallelexamples:GenericKubernetes:IncorrectArguments", ...
        "%s must be a character vector", name);
end
end

function iCheckInt(cluster, name)
% Throw an error if cluster.AdditionalProperties.(name) is not an integer.
iCheckHasProp(cluster, name);
object = cluster.AdditionalProperties.(name);
if ~isnumeric(object) || (rem(object, 1) ~= 0)
    error("parallelexamples:GenericKubernetes:IncorrectArguments", ...
        "%s must be an integer", name);
end
end

function iCheckOptional(cluster, name, checkerFcn)
% If an additional property exists, check it with checkerFcn.
if isprop(cluster.AdditionalProperties, name)
    checkerFcn(cluster, name)
end
end

function iCheckDependentProp(cluster, name, dependsOn)
% Check that if a given property is set, another property that it depends
% on is also set.
if ~isprop(cluster.AdditionalProperties, name)
    return
end
if ~isprop(cluster.AdditionalProperties, dependsOn)
    error("parallelexamples:GenericKubernetes:MissingAdditionalProperties", ...
        "If AdditionalProperties.%s is set, AdditionalProperties.%s must also be set", ...
        name, dependsOn);
end
end
