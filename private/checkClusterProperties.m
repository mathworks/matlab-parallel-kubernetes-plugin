function checkClusterProperties(cluster)
% Check that a cluster has the required properties and that its properties
% are of the correct data type.

% Copyright 2022 The MathWorks, Inc.

iCheckRequiredAdditionalProperties(cluster);
iCheckOptionalAdditionalProperties(cluster);
end

function iCheckRequiredAdditionalProperties(cluster)
% Check cluster has required properties and that they are of the correct type;
% throw an error if properties are missing or type mismatches are found.

iCheckCharOrString(cluster, "Image");
iCheckCharOrString(cluster, "ImagePullPolicy");
iCheckCharOrString(cluster, "ClusterJobStorageLocation");
iCheckInt(cluster, "ClusterUserID");
iCheckInt(cluster, "ClusterGroupID");
end

function iCheckOptionalAdditionalProperties(cluster)
% Check cluster's additional properties are of the correct type; throw an error
% if type mismatches are found.

iCheckOptional(cluster, "JobStorageServer", @iCheckCharOrString);
iCheckOptional(cluster, "MatlabServer", @iCheckCharOrString);
iCheckOptional(cluster, "Namespace", @iCheckCharOrString);
iCheckOptional(cluster, "KubeConfig", @iCheckCharOrString);
iCheckOptional(cluster, "KubeContext", @iCheckCharOrString);
iCheckOptional(cluster, "Timeout", @iCheckInt);
iCheckOptional(cluster, "MountMatlabFromCluster", @iCheckLogical);
iCheckOptional(cluster, "LicenseServer", @iCheckCharOrString);
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

function iCheckLogical(cluster, name)
% Throw an error if cluster.AdditionalProperties.(name) is not a logical array.
iCheckHasProp(cluster, name);
object = cluster.AdditionalProperties.(name);
if ~islogical(object)
    error("parallelexamples:GenericKubernetes:IncorrectArguments", ...
        "%s must be a logical array", name);
end
end

function iCheckOptional(cluster, name, checkerFcn)
% If an additional property exists, check it with checkerFcn.
if isprop(cluster.AdditionalProperties, name)
    checkerFcn(cluster, name)
end
end
