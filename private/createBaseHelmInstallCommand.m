function cmd = createBaseHelmInstallCommand(releaseName, jobUID, podNames, ...
    chartDir, cluster, environmentProperties)
% Create helm install command with settings common to independent and
% communicating jobs.

% Copyright 2022-2023 The MathWorks, Inc.

cmd = sprintf("helm install %s ""%s""", releaseName, chartDir);

cmd = appendHelmSetting(cmd, "username", getUsername());
cmd = appendHelmSetting(cmd, "jobUID", jobUID);
cmd = appendHelmSetting(cmd, "taskUIDs", podNames, true);
cmd = appendHelmSetting(cmd, "image", cluster.AdditionalProperties.Image);
cmd = appendHelmSetting(cmd, "imagePullPolicy", ...
    cluster.AdditionalProperties.ImagePullPolicy);
cmd = appendHelmSetting(cmd, "parallelServer.jobLocation", ...
    environmentProperties.JobLocation);
cmd = appendHelmSetting(cmd, "parallelServer.debug", iGetDebugSetting(cluster));
cmd = appendHelmSetting(cmd, "parallelServer.userID", ...
    cluster.AdditionalProperties.ClusterUserID);
cmd = appendHelmSetting(cmd, "parallelServer.groupID", ...
    cluster.AdditionalProperties.ClusterGroupID);
cmd = appendHelmSetting(cmd, "parallelServer.storageConstructor", ...
    environmentProperties.StorageConstructor);
cmd = appendHelmSetting(cmd, "parallelServer.matlabArgs", ...
    environmentProperties.MatlabArguments);
cmd = appendHelmSetting(cmd, "numThreads", cluster.NumThreads);
cmd = appendHelmSetting(cmd, "jobStoragePVC", ...
    cluster.AdditionalProperties.JobStoragePVC);
cmd = appendHelmSetting(cmd, "jobStoragePath", ...
    cluster.AdditionalProperties.JobStoragePath);

useMatlabPVC = isprop(cluster.AdditionalProperties, "MatlabPVC");
if useMatlabPVC
    cmd = appendHelmSetting(cmd, "matlabPVC", cluster.AdditionalProperties.MatlabPVC);
    cmd = appendHelmSetting(cmd, "matlabPath", cluster.AdditionalProperties.MatlabPath);
end

cmd = appendOptionalHelmSetting(cmd, cluster, "LicenseServer", "licenseServer");

end

function enableDebug = iGetDebugSetting(cluster)
% Determine the debug setting. Setting to true makes the MATLAB workers
% output additional logging. If EnableDebug is set in the cluster object's
% AdditionalProperties, that takes precedence. Otherwise, look for the
% PARALLEL_SERVER_DEBUG and MDCE_DEBUG environment variables in that order.
% If nothing is set, debug is false.
enableDebug = 'false';
if isprop(cluster.AdditionalProperties, 'EnableDebug')
    enableDebug = char(string(cluster.AdditionalProperties.EnableDebug));
else
    environmentVariablesToCheck = {'PARALLEL_SERVER_DEBUG', 'MDCE_DEBUG'};
    for idx = 1:numel(environmentVariablesToCheck)
        debugValue = getenv(environmentVariablesToCheck{idx});
        if ~isempty(debugValue)
            enableDebug = debugValue;
            break
        end
    end
end
end
