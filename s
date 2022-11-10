[1mdiff --git a/README.md b/README.md[m
[1mindex f826c82..656dacd 100644[m
[1m--- a/README.md[m
[1m+++ b/README.md[m
[36m@@ -1,7 +1,5 @@[m
 # Parallel Computing Toolbox plugin for MATLAB Parallel Server with Kubernetes[m
 [m
[31m-[![View on File Exchange - TODO replace this link with kubernetes](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/72125)[m
[31m-[m
 Parallel Computing Toolbox&trade; provides the `Generic` cluster type for submitting MATLAB&reg; jobs to a cluster running a third-party scheduler.[m
 `Generic` uses a set of plugin scripts to define how your machine running MATLAB or Simulink&reg; communicates with your scheduler.[m
 You can customize the plugin scripts to configure how MATLAB interacts with the scheduler to best suit your cluster's setup and to support custom submission options.[m
[36m@@ -311,7 +309,7 @@[m [mNamespace                 | String   | The Kubernetes namespace to use. If this[m
 KubeConfig                | String   | The location of the config file used by `kubectl` to access your cluster. For more information, see the [Kubernetes config file documentation](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/). If this property is not specified, the default location (`$HOME/.kube/config`) is used.[m
 KubeContext               | String   | The context within your Kubernetes config file to use if you have multiple clusters or user configurations within that file. For more information, see the [Kubernetes context documentation](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/). If this property is not specified, the default context is used.[m
 LicenseServer             | String   | The port and hostname of a machine running a Network License Manager in the format port@hostname.[m
[31m-Timeout                   | Number   | The amount of time in seconds to wait for pods to load in a pool or SPMD job. By default, this is set to 600 seconds, but can increase it if you have a slow network connection.[m
[32m+[m[32mTimeout                   | Number   | The amount of time in seconds that MATLAB waits for all worker pods to start running after the first worker starts in a pool or SPMD job. By default, this property is set to 600 seconds.[m
 [m
 If the cluster administrator installed specific versions of the Helm and Kubectl executables on the cluster, set the following additional properties:[m
 [m
[36m@@ -405,7 +403,25 @@[m [mwait(job);[m
 results = fetchOutputs(job)[m
 ```[m
 [m
[31m-### Open a Parallel Pool[m
[32m+[m[32m### Submit Work for Batch Processing with a Parallel Pool[m
[32m+[m
[32m+[m[32mYou can use the `batch` command to create a parallel pool by using the `'Pool'` name-value pair argument.[m
[32m+[m
[32m+[m[32m```matlab[m
[32m+[m[32m% Create and submit a batch pool job to the cluster[m
[32m+[m[32mjob = batch([m
[32m+[m[32m    c, ... % cluster object created using parcluster[m
[32m+[m[32m    @sqrt, ... % function/script to run[m
[32m+[m[32m    1, ... % number of output arguments[m
[32m+[m[32m    {[64 100]}, ... % input arguments[m
[32m+[m[32m    'Pool', 3); ... % use a parallel pool with three workers[m
[32m+[m[32m```[m
[32m+[m
[32m+[m[32mOnce the first worker has started running on the Kubernetes cluster, the worker will wait up to the number of seconds specified in `cluster.AdditionalProperties.Timeout` (default 600 seconds) for the remaining workers to start running before failing.[m
[32m+[m[32mIf your cluster does not have enough resources to start all of the workers before the timeout, your batch pool job will fail.[m
[32m+[m[32mIn this case, use fewer workers for your batch pool job, increase the timeout, or wait until your Kubernetes cluster has more resources available.[m
[32m+[m
[32m+[m[32m### Open an Interactive Parallel Pool[m
 [m
 A parallel pool (parpool) is a group of MATLAB workers that you can interactively run work on.[m
 Parallel pools are only supported if the Kubernetes cluster is running on the same network as your computer.[m
[1mdiff --git a/communicating-job/templates/job.yaml b/communicating-job/templates/job.yaml[m
[1mindex 9dad28d..7f2a160 100644[m
[1m--- a/communicating-job/templates/job.yaml[m
[1m+++ b/communicating-job/templates/job.yaml[m
[36m@@ -83,9 +83,9 @@[m [mspec:[m
         - name: JOB_UID[m
           value: {{ .Values.jobUID }}[m
         - name: TIMEOUT[m
[31m-          value: {{ .Values.timeout | default 300 | quote }}[m
[32m+[m[32m          value: {{ .Values.timeout | quote }}[m
         - name: TASK_UIDS[m
[31m-          value: {{ join "," .Values.taskUIDs }}[m
[32m+[m[32m          value: {{ slice .Values.taskUIDs 1 | join "," }}[m
         - name: LOGFILE[m
           value: {{ .Values.logfile }}[m
         - name: HELM[m
[1mdiff --git a/communicatingSubmitFcn.m b/communicatingSubmitFcn.m[m
[1mindex e842aaf..660614e 100644[m
[1m--- a/communicatingSubmitFcn.m[m
[1m+++ b/communicatingSubmitFcn.m[m
[36m@@ -32,8 +32,8 @@[m [mcmd = appendHelmSetting(cmd, "numberOfTasks", ...[m
 cmd = appendHelmSetting(cmd, "serviceAccountName", ...[m
     lower(sprintf("%s-serviceaccount-%s", releaseName, jobUID)));[m
 cmd = appendHelmSetting(cmd, "logfile", getRelativeLogLocation(cluster, job));[m
[32m+[m[32mcmd = appendHelmSetting(cmd, "timeout", getTimeout(cluster));[m
 [m
[31m-cmd = appendOptionalHelmSetting(cmd, cluster, "Timeout", "timeout");[m
 cmd = appendOptionalHelmSetting(cmd, cluster, "HelmDir", "clusterHelmDir");[m
 cmd = appendOptionalHelmSetting(cmd, cluster, "KubectlDir", "clusterKubectlDir");[m
 [m
[1mdiff --git a/getJobStateFcn.m b/getJobStateFcn.m[m
[1mindex 32fc36b..570c855 100644[m
[1m--- a/getJobStateFcn.m[m
[1m+++ b/getJobStateFcn.m[m
[36m@@ -17,7 +17,7 @@[m [mcommandToRun = sprintf("kubectl get pod -l jobUID=""%s"" -o json", jobUID);[m
 [~, cmdOut] = runKubeCmd(commandToRun, cluster, job);[m
 podInfo = jsondecode(cmdOut);[m
 [m
[31m-clusterState = iExtractJobState(podInfo, numel(job.Tasks));[m
[32m+[m[32mclusterState = iExtractJobState(podInfo, job);[m
 [m
 % If we could determine the cluster's state, we'll use that, otherwise[m
 % stick with MATLAB's job state.[m
[36m@@ -26,7 +26,7 @@[m [mif ~strcmp(clusterState, 'unknown')[m
 end[m
 end[m
 [m
[31m-function state = iExtractJobState(podInfo, numTasks)[m
[32m+[m[32mfunction state = iExtractJobState(podInfo, job)[m
 % Extract the job state from the output of kubectl.[m
 % See https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase for pod phases[m
 [m
[36m@@ -35,6 +35,7 @@[m [mnumRunning  = 0;[m
 numFinished = 0;[m
 numFailed   = 0;[m
 [m
[32m+[m[32mfailedPods = {};[m
 for idx = 1:numel(podInfo.items)[m
     if strcmp(podInfo.items(idx).status.phase, "Pending")[m
         numPending = numPending + 1;[m
[36m@@ -44,11 +45,12 @@[m [mfor idx = 1:numel(podInfo.items)[m
         numFinished = numFinished + 1;[m
     elseif strcmp(podInfo.items(idx).status.phase, 'Failed')[m
         numFailed = numFailed + 1;[m
[32m+[m[32m        failedPods{end + 1} = podInfo.items(idx); %#ok<AGROW>[m
     end[m
 end[m
 [m
 % If pods for all tasks have finished, the job is finished[m
[31m-if numFinished == numTasks[m
[32m+[m[32mif numFinished == numel(job.Tasks)[m
     state = 'finished';[m
     return[m
 end[m
[36m@@ -70,8 +72,47 @@[m [mend[m
 if numFailed > 0[m
     % Set this job to be failed[m
     state = 'failed';[m
[32m+[m[32m    iCheckExitCode(failedPods, job);[m
     return[m
 end[m
 [m
 state = 'unknown';[m
 end[m
[32m+[m
[32m+[m[32mfunction iCheckExitCode(failedPods, job)[m
[32m+[m[32m% Throw an error if a known exit code was returned by the first failed pod.[m
[32m+[m[32m% Exit codes:[m
[32m+[m[32m%    2: Worker does not have write permission for the job storage[m
[32m+[m[32m%       location.[m
[32m+[m[32m%    3: Communicating job timed out waiting for all worker pods to start.[m
[32m+[m[32mexitCode = failedPods{1}.status.containerStatuses.state.terminated.exitCode;[m
[32m+[m
[32m+[m[32mcluster = job.Parent;[m
[32m+[m[32mif exitCode == 2[m
[32m+[m[32m    iError(job, 'parallelexamples:GenericKubernetes:NoWritePermissionOnCluster', ...[m
[32m+[m[32m        sprintf('Worker with user ID = %d, group ID = %d does not have permission to write to the job storage location on the cluster (%s).', ...[m
[32m+[m[32m        cluster.AdditionalProperties.ClusterUserID, ...[m
[32m+[m[32m        cluster.AdditionalProperties.ClusterGroupID, ...[m
[32m+[m[32m        cluster.AdditionalProperties.ClusterJobStorageLocation));[m
[32m+[m[32melseif exitCode == 3 && iIsCommunicatingJob(job)[m
[32m+[m[32m    iError(job, 'parallelexamples:GenericKubernetes:CommunicatingJobTimeout', ...[m
[32m+[m[32m        sprintf('Job timed out after %d seconds waiting for %d workers to start. Submit a job with fewer workers or increase the timeout by editing the cluster''s "Timeout" additional property.', ...[m
[32m+[m[32m        getTimeout(cluster), max(job.NumWorkersRange)));[m
[32m+[m[32mend[m
[32m+[m[32mend[m
[32m+[m
[32m+[m[32mfunction iError(job, errId, message)[m
[32m+[m[32m% Throw an error if this error has not been thrown before for this job.[m
[32m+[m[32mcluster = job.Parent;[m
[32m+[m[32mpreviousErrors = cluster.getJobClusterData(job).Errors;[m
[32m+[m[32mif ~any(strcmp(errId, previousErrors))[m
[32m+[m[32m    previousErrors{end + 1} = errId;[m
[32m+[m[32m    insertJobData(cluster, job, "Errors", previousErrors);[m
[32m+[m[32m    error(errId, message);[m
[32m+[m[32mend[m
[32m+[m[32mend[m
[32m+[m
[32m+[m[32mfunction isCommunicatingJob = iIsCommunicatingJob(job)[m
[32m+[m[32mcommunicatingJobTypes = ["pool", "spmd", "concurrent"];[m
[32m+[m[32misCommunicatingJob = any(strcmp(job.Type, communicatingJobTypes));[m
[32m+[m[32mend[m
[1mdiff --git a/private/checkClusterProperties.m b/private/checkClusterProperties.m[m
[1mindex 091b1ed..f88b71e 100644[m
[1m--- a/private/checkClusterProperties.m[m
[1m+++ b/private/checkClusterProperties.m[m
[36m@@ -29,7 +29,7 @@[m [miCheckOptional(cluster, "Namespace", @iCheckCharOrString);[m
 iCheckOptional(cluster, "KubeConfig", @iCheckCharOrString);[m
 iCheckOptional(cluster, "KubeContext", @iCheckCharOrString);[m
 iCheckOptional(cluster, "Timeout", @iCheckInt);[m
[31m-iCheckOptional(cluster, "MountMatlab", @iCheckLogical);[m
[32m+[m[32miCheckOptional(cluster, "MountMatlabFromCluster", @iCheckLogical);[m
 iCheckOptional(cluster, "LicenseServer", @iCheckCharOrString);[m
 end[m
 [m
[1mdiff --git a/private/setJobData.m b/private/setJobData.m[m
[1mindex 6eb96c8..90c3126 100644[m
[1m--- a/private/setJobData.m[m
[1m+++ b/private/setJobData.m[m
[36m@@ -9,6 +9,7 @@[m [mfunction setJobData(cluster, job, jobUID, releaseNames, podNames)[m
 insertJobData(cluster, job, "HelmReleases", releaseNames);[m
 insertJobData(cluster, job, "JobUID", jobUID);[m
 insertJobData(cluster, job, "HelmUninstalled", false);[m
[32m+[m[32minsertJobData(cluster, job, "Errors", {});[m
 [m
 set(job.Tasks, 'SchedulerID', podNames);[m
 end[m
