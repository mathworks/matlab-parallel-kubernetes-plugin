function cmd  = applyOnlineLicensingSettings(cmd, cluster, job, ...
    jobUID, environmentProperties)
% Append online licensing environment variables to a Helm command and create
% a Kubernetes secret containing the user login token. Store the secret name in
% the cluster's job data so it can be deleted later.

% Copyright 2022 The MathWorks, Inc.

cmd = appendHelmSetting(cmd, "mlmWebLicense", environmentProperties.UseMathworksHostedLicensing);
cmd = appendHelmSetting(cmd, "mlmWebID", environmentProperties.LicenseWebID);
cmd = appendHelmSetting(cmd, "licenseNumber", environmentProperties.LicenseNumber);

[secretName, key] = iCreateUserCredSecret(environmentProperties, cluster, job, jobUID);
cmd = appendHelmSetting(cmd, "userCredSecretName", secretName);
cmd = appendHelmSetting(cmd, "userCredKeyName", key);

insertJobData(cluster, job, "UserCredSecret", secretName);
end

function [secretName, key] = iCreateUserCredSecret(environmentProperties, cluster, job, jobUID)
% Create a kubernetes secret containing the user login token; return its name
% and the key containing the token.

secretName = "usercred-" + jobUID;
key = "userCred";
cmd = sprintf("kubectl create secret generic %s --from-literal=%s=%s", ...
    secretName, key, environmentProperties.UserToken);
runKubeCmd(cmd, cluster, job);

end
