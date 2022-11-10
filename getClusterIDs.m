function [clusterUserID, clusterGroupID] = getClusterIDs(hostname, varargin)
% Get user ID and group ID for a user on a given host. If run without
% output arguments, the IDs will be displayed rather than returned.
%
% getClusterIDs(hostname, username) prompts for a password to login to the
% cluster.
%
% getClusterIDs(hostname, username, 'IdentityFilename', filename) uses an
% identity file to login to the cluster, assuming the identity file does
% not require a password.
%
% getClusterIDs(hostname, username, 'IdentityFilename', filename,
% 'IdentityFileHasPassphrase', true) prompts for the passphrase for the
% identity file to login to the cluster.

% Copyright 2022 The MathWorks, Inc.

rca = parallel.cluster.RemoteClusterAccess(varargin{:});
rca.connect(hostname);
cleanupRca = onCleanup(@() delete(rca));

userID = iRunCommand(rca, "id -u");
groupID = iRunCommand(rca, "id -g");

if nargout == 0
    disp("ClusterUserID: " + userID);
    disp("ClusterGroupID: " + groupID);
else
    clusterUserID = userID;
    clusterGroupID = groupID;
end
end

function cmdOut = iRunCommand(rca, cmd)
% Run a command through a remote connection and check it was successful.

[exitCode, cmdOut] = rca.runCommand(cmd);
if exitCode ~= 0
    error('parallelexamples:GenericKubernetes:CommandFailed', ...
        'Failed to run command ""%s"" through remote cluster access. Command output: ""%s""', ...
        cmd, cmdOut);
end
end
