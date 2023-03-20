function [exitCode, cmdOut] = runKubeCmd(commandToRun, cluster, job, throwIfFailed)
% Append a kubectl or helm command with cluster-specific settings then run it.
% If the command returns a nonzero exit code, raise an error if throwIfFailed
% is true or unset, or a warning otherwise.

% Copyright 2022-2023 The MathWorks, Inc.

if nargin < 4
    throwIfFailed = true;
end

commandToRun = iAppendKubeSettings(commandToRun, cluster, job);
dctSchedulerMessage(4, "Running command: %s", commandToRun);
[exitCode, cmdOut] = system(commandToRun);
cmdOut = strip(cmdOut);

if exitCode ~= 0 && throwIfFailed
    error("parallelexamples:GenericKubernetes:CommandFailed", ...
        "Command ""%s"" failed with message ""%s""", commandToRun, cmdOut);
end
end

function cmd = iAppendKubeSettings(cmd, cluster, job)
% Append the following custom settings to a command if they are set in the
% cluster's additional properties:
% --kubeconfig: path to kubenertes config file;
% --context: name of kubernetes cluster to use (this option is --kube-context
%            for helm commands);
% --namespace: custom namespace if set in additional properties; otherwise
%              use namespace "matlab"
cmd = iAppendIfPropertyExists(cmd, cluster, "kubeconfig", "KubeConfig");
cmd = iAppendContext(cmd, cluster);
cmd = iAppendNamespace(cmd, cluster, job);
end

function cmd = iAppendSetting(cmd, name, val)
% Append a setting to a command
cmd = sprintf("%s --%s ""%s""", cmd, name, val);
end

function cmd = iAppendIfPropertyExists(cmd, cluster, settingName, propName)
% Append a setting to a command only if a property exists in cluster's
% additional properties
if isprop(cluster.AdditionalProperties, propName)
    cmd = iAppendSetting(cmd, settingName, cluster.AdditionalProperties.(propName));
end
end

function cmd = iAppendContext(cmd, cluster)
% Append the kube-context (i.e. the name of the cluster) to a the command if
% a kube-context is set in the cluster's additional properties. Note that
% this setting is "--kube-context" for helm commands and "--context" for
% kubectl commands.

if startsWith(cmd, "helm")
    contextSetting = "kube-context";
else
    contextSetting = "context";
end
cmd = iAppendIfPropertyExists(cmd, cluster, contextSetting, "KubeContext");
end

function cmd = iAppendNamespace(cmd, cluster, job)
% Append the kubernetes namespace to the command; if a namespace has not yet
% been set in the job's cluster data, set it.
jobData = cluster.getJobClusterData(job);
if isempty(jobData) || ~isfield(jobData, "Namespace")
    setNamespace(cluster, job);
    jobData = cluster.getJobClusterData(job);
end
cmd = iAppendSetting(cmd, "namespace", jobData.Namespace);
end
