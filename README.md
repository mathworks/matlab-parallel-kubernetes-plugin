# Parallel Computing Toolbox plugin for MATLAB Parallel Server with Kubernetes

[![View Plugin for MATLAB Parallel Server with Kubernetes on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://mathworks.com/matlabcentral/fileexchange/120243-plugin-for-matlab-parallel-server-with-kubernetes)

Parallel Computing Toolbox&trade; provides the `Generic` cluster type for submitting MATLAB&reg; jobs to a cluster running a third-party scheduler.
`Generic` uses a set of plugin scripts to define how your machine running MATLAB or Simulink&reg; communicates with your scheduler.
You can customize the plugin scripts to configure how MATLAB interacts with the scheduler to best suit your cluster's setup and to support custom submission options.

This repository contains MATLAB code files and shell scripts that you can use to submit jobs from a MATLAB or Simulink session running on Windows&reg;, Linux&reg;, or macOS to a Kubernetes&reg; cluster.

The following instructions are in two sections.
The first section describes how to prepare the Kubernetes cluster to run MATLAB Parallel Server workers.
To configure the Kubernetes cluster for MATLAB Parallel Server as cluster administrator see [One-Time Cluster Setup Instructions](#one-time-cluster-setup-instructions-cluster-administrators).

The second section describes how to integrate Parallel Computing Toolbox installed on your computer with the Kubernetes cluster.
To run MATLAB Parallel Server workers on the Kubernetes cluster as MATLAB users see [Cluster Profile Creation Instructions](#cluster-profile-creation-instructions).

## Usage Notes and Limitations

### Shared Job Storage Location Requirement

MATLAB Parallel Server with Kubernetes requires both your computer and the Kubernetes cluster to have read and write access to a shared directory.
You must make this directory available to the cluster via a Kubernetes PersistentVolumeClaim.

### Cluster access requirement

MATLAB Parallel Server with Kubernetes requires your computer to have access to the cluster via Kubectl.
You must have the ability to get, list, create and delete Kubernetes pods, jobs and secrets.

### Limitations

Interactive parallel pools are not supported for remote Kubernetes clusters, such as a cluster running in the cloud.
You can only use interactive parallel pools if your Kubernetes cluster is running on the same network as your computer.

## One-Time Cluster Setup Instructions (Cluster Administrators)

The instructions in this section are for Kubernetes cluster administrators to prepare the cluster for running MATLAB Parallel Server workers.
Before proceeding, ensure that you have the products required for one-time cluster setup listed below.

### Products Required

- [Kubernetes](https://kubernetes.io/) version 1.21 or later running on the cluster.
- [Docker](https://docs.docker.com/get-docker/) installed on your computer.
- [Kubectl](https://kubernetes.io/docs/tasks/tools/) installed on your computer.

### Setup instructions

#### 1. Download or Clone this Repository

To download a zip file of this repository, at the top of this repository page, select **Code > Download ZIP**.
Alternatively, to clone this repository to your computer with git installed, run the following command on your operating system's command line:
```
git clone https://github.com/mathworks/matlab-parallel-kubernetes-plugin
```

#### 2. Create a Kubernetes Namespace and Limit Its Resources

Kubernetes uses namespaces to separate groups of resources.
For more information, see the [Kubernetes namespace documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/).
It is recommended that you run MATLAB Parallel Server jobs inside a specific namespace on your cluster so that they are separate from other resources on the cluster.

If users do not specify a custom namespace in the cluster profile, MATLAB Parallel Server workers will attempt to run in a namespace called `matlab`.
MATLAB will attempt to create the `matlab` namespace if it does not already exist.
If MATLAB cannot create the `matlab` namespace, the workers will run in the `default` namespace.

To create a custom namespace, run
```
kubectl create namespace my-namespace
```
where `my-namespace` is the name you have chosen.

##### Limiting Kubernetes Pods in a Namespace

Within a Kubernetes namespace, you can limit the number of pods that may run simultaneously.
Each MATLAB Parallel Server worker requires one pod.
By limiting pods, you can limit the number of MATLAB Parallel Server workers that run at any one time.
If your MATLAB Parallel Server license has less than 200 workers, you should limit the number of pods to the number of MATLAB Parallel Server workers by running:
```
kubectl create resourcequota quota-name --namespace my-namespace --hard pods=numWorkers
```
where `quota-name` is the name of the created resource quota, `my-namespace` is the namespace you are using and `numWorkers` is the number of MATLAB Parallel Server workers on your license.

#### 3. Set up a PersistentVolumeClaim for job storage

You must ensure that each MATLAB Parallel Server user has read and write access to a directory on their computer that is shared with the cluster via a PersistentVolumeClaim.
The account the user has access to on the cluster must also have read and write access to that directory.

You can create a Kubernetes PersistentVolumeClaim either statically from a PersistentVolume or dynamically from a StorageClass.
For more information, see the [Kubernetes PersistentVolume documentation](https://https://kubernetes.io/docs/concepts/storage/persistent-volumes/).

For example, if you have an on-premise Kubernetes cluster, you can create a PersistentVolume from an NFS server that is visible to your cluster.
Alternatively, if you have a Kubernetes cluster in AWS, you can create a StorageClass to provision storage from an EFS instance.
For details, see the [Amazon EFS CSI driver documentation](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html).
In either case, you must create a PersistentVolumeClaim to provision storage from your chosen source and share the name of this PersistentVolumeClaim with your cluster users.

Here is an example of a configuration file for a PersistentVolumeClaim:
```
apiVersion: v1
kind: PersistentVolumeClaim
namespace: <my-namespace>
metadata:
  name: <pvc-name>
spec:
  volumeName: <pv-name>
  storageClassName: <storage-class-name>
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: <capacity>
```
Set `<my-namespace>` to the namespace you created in step 2.
Set `<pvc-name>` to your desired name for the PersistentVolumeClaim and `<capacity>` to the amount of storage you wish to provision for your job storage location.
For information on the units you can use for storage capacity, see the [Kubernetes resource management documentation](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/).
If you are using a PersistentVolume, set `<pv-name>` to the name of this PersistentVolume and `<storage-class-name>` to `""`.
If you are using a StorageClass for dynamic provisioning, omit the `volumeName` field and set `<storage-class-name>` to the name of your StorageClass.

#### 4. (Optional) Share your own MATLAB and MATLAB Parallel Server Installation with the Cluster

The cluster must have access to a MATLAB and MATLAB Parallel Server installation.
You can either build this into the Docker image (see step 5) or use your own MATLAB and MATLAB Parallel Server installation.
To share your own MATLAB and MATLAB Parallel Server installation with the cluster, create a PersistentVolumeClaim containing the installation.

#### 5. Build the Docker Image for MATLAB Parallel Server on the Cluster

To run MATLAB Parallel Server workers on the Kubernetes cluster, you must build a suitable Docker image using the Dockerfile included in this repository and make it available on the cluster.

To build the image, first navigate to the `image/` directory inside this repository.

When building, you must specify a MATLAB release number.
This must match the version of MATLAB installed on the computers of the MATLAB Parallel Server users.

If you are sharing your own MATLAB and MATLAB Parallel Server installation with the cluster (see step 4), follow Option 1. Otherwise, follow Option 2.

##### Option 1: Build the Docker Image Without MATLAB Installed
To build a Docker image without a built-in MATLAB installation, specify a MATLAB release number with a lowercase "r".
For example, if the MATLAB release is R2022a, run the following from within the `image/` directory:
```
docker build . -t image-name --build-arg MATLAB_RELEASE=r2022a
```
where `image-name` is the name you have chosen for your image.

##### Option 2 (Linux): Build the Docker Image With MATLAB Installed
To build a Docker image with a built-in MATLAB and MATLAB Parallel Server installation, set the argument `INSTALL_MATLAB=true`. This option is only supported when you build the Docker image on Linux.

To build the image, run the following command from within the `image/` directory:
```
docker build . -t image-name --build-arg MATLAB_RELEASE=release --build-arg INSTALL_MATLAB=true --build-arg LICENSE_SERVER=port@hostname ADDITIONAL_PRODUCTS="Product1 Product2"
```

By default, this will install all MATLAB toolboxes included with a MATLAB Parallel Server license.
These toolboxes are listed for each release in files under `image/product_lists`.
To modify the toolboxes to install, edit the file corresponding to your desired MATLAB release before running the `docker build` command.
The toolbox names should match the product names listed on the MathWorks product page with any spaces replaced by underscores.
For a full list of product names, see the [MathWorks product page](https://www.mathworks.com/products.html).

Once you have built the image, you must make it available on your Kubernetes cluster.
You can host it in a remote repository or pull the image to each node to obtain a local copy.

#### 6. Restrict Access to Kubernetes Secrets if Using Online Licensing

MATLAB online licensing sends login tokens to the Kubernetes pods via Kubernetes secrets.
If you use MATLAB online licensing, enable encryption at rest and restrict access to safely use Kubernetes secrets.
For more information, see the [Kubernetes secret documentation](https://kubernetes.io/docs/concepts/configuration/secret/).

## Cluster Profile Creation Instructions

The instructions in this section are for MATLAB users to integrate their Parallel Computing Toolbox with the Kubernetes cluster.
For help with the following instructions, contact your cluster administrator.
Before proceeding, ensure that you have the products required for running MATLAB Parallel Server with Kubernetes listed below.

### Products required

- [MATLAB](https://mathworks.com/products/matlab.html) and [Parallel Computing Toolbox](https://mathworks.com/products/parallel-computing.html), release R2019b or newer, installed on your computer.
Refer to the documentation for [how to install MATLAB and toolboxes](https://mathworks.com/help/install/index.html) on your computer.
- A [MATLAB Parallel Server](https://mathworks.com/products/matlab-parallel-server.html)&trade; license.
- [Kubectl](https://kubernetes.io/docs/tasks/tools/) installed on your computer.
- [Helm](https://helm.sh/docs/intro/quickstart/) installed on your computer.

### Setup instructions

#### 1. Set Up Access to Kubernetes Cluster from Your Computer

Ensure you have access to the Kubernetes cluster from your computer via the Kubectl command line tool.
The access method is dependent on the cluster.
On Linux, for example, Kubectl and Helm are typically installed using the distribution's package manager.
They are then usually configured to access the correct cluster by modifying the `~/.kube/config` file.
Contact your cluster administrator for assistance.

#### 2. Download or Clone this Repository

To download a zip file of this repository, at the top of this repository page, select **Code > Download ZIP**.
Alternatively, to clone this repository to your computer with git installed, run the following command on your operating system's command line:
```
git clone https://github.com/mathworks/matlab-parallel-kubernetes-plugin
```
You can execute this command from the MATLAB command line by adding a `!` before the command.

#### 3. Create the Cluster Profile

You can create a cluster profile by using either the Cluster Profile Manager or the MATLAB command line.

To open the Cluster Profile Manager, on the **Home** tab, in the **Environment** section, select **Parallel > Create and Manage Clusters**.
Within the Cluster Profile Manager, select **Add Cluster Profile > Generic** from the menu to create a new `Generic` cluster profile.

Alternatively, for a command line workflow without using graphical user interfaces, create a new `Generic` cluster object by running:
```matlab
c = parallel.cluster.Generic;
```

#### 4. Configure Cluster Properties

The table below gives the minimum properties required for `Generic` to work correctly.
For a full list of cluster properties, see the [`parallel.Cluster` documentation](https://mathworks.com/help/parallel-computing/parallel.cluster.html).

**Property**          | **Value**
----------------------|----------------
JobStorageLocation    | Location where job data is stored on your machine.
NumWorkers            | Number of workers available on your cluster. Set this to a value no greater than either the number of workers your license allows or the total number of CPUs available on your cluster.
OperatingSystem       | 'unix'
PluginScriptsLocation | Full path to the folder containing this file.

The following cluster properties are optional:

**Property**               | **Value**
---------------------------|----------------
RequiresOnlineLicensing    | Set this property to `true` if you wish to use online licensing for MATLAB Parallel Server.
LicenseNumber              | License number of your MATLAB Parallel Server license. Set this option only if your MathWorks account is associated with more than one MATLAB Parallel Server license.
NumThreads                 | Number of computational threads to use on each worker (default: 1). Set this to a value no greater than the maximum number of CPUs available on a single node in your cluster.

In the Cluster Profile Manager, set each property value in the boxes provided.
Alternatively, at the command line, set each property on the cluster object using dot notation:
```matlab
c.JobStorageLocation = '/data/matlabJobs';
% etc.
```

At the command line, you can also set properties at the same time you create the `Generic` cluster object, by specifying name-value pairs in the constructor:
```matlab
c = parallel.cluster.Generic( ...
    'JobStorageLocation', '/data/matlabJobs', ...
    'NumWorkers', 20, ...
    'OperatingSystem', 'unix', ...
    'PluginScriptsLocation', '/data/MatlabKubernetesPlugin');
```

#### 5. Get User ID and Group ID on the Cluster

To allow the MATLAB Parallel Server workers to write to your job storage location on the cluster, you must provide the user ID and group ID of your account on the cluster.

If you know the hostname of one of the node machines and your username on that machine, you can use the function `getClusterIDs` provided with the plugin scripts to get your user ID and group ID.

In MATLAB, navigate to the directory containing the Kubernetes plugin scripts.
If you have a password to log into the machine, run:
```matlab
getClusterIDs(hostname, username);
```
and enter the password when prompted.

If you have access to the cluster via an identity file that does not require a password, run:
```matlab
getClusterIDs(hostname, username, 'IdentityFile', filename);
```
where `filename` is the path to the identity file.

If you have access to the cluster via an identity file that requires a password, run:
```matlab
getClusterIDs(hostname, username, 'IdentityFile', filename, 'IdentityFileHasPassword', true);
```
and enter the password when prompted.

All authentication modes supported by `RemoteClusterAccess` are supported.
For more information, see the [`RemoteClusterAccess` documentation](https://mathworks.com/help/parallel-computing/remoteclusteraccess.html).

#### 6. Configure AdditionalProperties

You can use `AdditionalProperties` as a way of modifying the behaviour of `Generic` without having to edit the plugin scripts.
By modifying the plugins, you can add support for your own custom `AdditionalProperties`.

In the Cluster Profile Manager, add new `AdditionalProperties` by clicking **Add** under the table of `AdditionalProperties`.
On the command line, use dot notation to add new fields:
```matlab
c.AdditionalProperties.Image = 'imageName';
```

The following `AdditionalProperties` are required:

**Property Name**         | **Type** | **Description**
--------------------------|----------|----------------
Image                     | String   | If the image is hosted remotely, set to the URL of the image. If the image is available locally on the cluster, set to the name of the image.
ImagePullPolicy           | String   | If the image is hosted remotely, set to `'Always'`. If the image is available locally on the cluster, set to `'Never'`.
JobStoragePVC             | String   | Name of the PersistentVolumeClaim to use for storing job data.
JobStoragePath            | String   | Path to the directory to use for storing job data within the PersistentVolume.
ClusterUserID             | Number   | The ID of your user account on the cluster.
ClusterGroupID            | Number   | The group ID of your user account on the cluster.

If the cluster administrator chose to share a MATLAB and MATLAB Parallel Server installation with the cluster rather than installing MATLAB and MATLAB Parallel Server on the Docker image, set the following additional properties:

**Property Name**         | **Type** | **Value**
--------------------------|----------|----------
MatlabPVC                 | String   | Name of the PersistentVolumeClaim containing MATLAB and MATLAB Parallel Server.
MatlabPath                | String   | Path to the MATLAB installation within the PeristentVolume.

The following additional properties are optional:

**Property Name**         | **Type** | **Description**
--------------------------|----------|----------------
Namespace                 | String   | The Kubernetes namespace to use. If you do not specify this property, MATLAB will use the `matlab` namespace. If MATLAB cannot create the `matlab` namespace, the workers will run in the `default` namespace.
KubeConfig                | String   | The location of the config file that `kubectl` uses to access your cluster. For more information, see the [Kubernetes config file documentation](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/). If you do not specify this property, MATLAB will use the default location (`$HOME/.kube/config`).
KubeContext               | String   | The context within your Kubernetes config file to use if you have multiple clusters or user configurations within that file. For more information, see the [Kubernetes context documentation](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/). If you do not specify this property, MATLAB will use the default context.
LicenseServer             | String   | The port and hostname of a machine running a Network License Manager in the format port@hostname.
Timeout                   | Number   | The amount of time in seconds that MATLAB waits for all worker pods to start running after the first worker starts in a pool or SPMD job. By default, this property is set to 600 seconds.

#### 7. Save Your New Profile

In the Cluster Profile Manager, click **Done**.
If creating the cluster on the command line, run:
```matlab
saveAsProfile(c, "myKubernetesCluster");
```
Your cluster profile is now ready to use.

#### 8. Validate the Cluster Profile

Cluster validation submits one of each type of job to test the cluster profile has been configured correctly.
If your Kubernetes cluster is running on a different network to your computer, such as in the cloud, uncheck the "Parallel pool test" box; interactive parallel pools are not supported for remote clusters.
In the Cluster Profile Manager, click the **Validate** button.
All stages should pass successfully, except the "Parallel pool test" stage if you have a remote cluster.
If you make a change to a cluster profile, you can rerun cluster validation to ensure there are no errors.
You do not need to validate each time you use the profile or each time you start MATLAB.

#### Debugging cluster validation problems

If cluster validation fails, you can investigate using the `inspectPods` function provided in the same directory as the plugin scripts.
First, create a job object for use in debugging.
For example, to create and submit an independent job, run:
```matlab
c = parcluster("myKubernetesCluster");
job = createJob(c);
createTask(job, @plus, 1, {1, 1});
submit(job);
```

To inspect the status of the Kubernetes pods associated with the job, navigate to the plugin script location from the MATLAB command line and run the following:
```matlab
inspectPods(job);
```
This displays the states of the Kubernetes pods associated with that job.

To obtain further information on a specific pod corresponding to a single task of a job, get the task object by indexing `job.Tasks`.
To get the first task, for example, run:
```matlab
task = job.Tasks(1);
```

To display detailed information about the Kubernetes pod corresponding to that task, run:
```matlab
inspectPods(task);
```

For help debugging the displayed information, contact your cluster administrator.

## Examples

First create a cluster object using your profile:
```matlab
c = parcluster("myKubernetesCluster")
```

### Submit Work for Batch Processing

The `batch` command runs a MATLAB script or function on a worker on the cluster.
For more information about batch processing, see the documentation for the [batch command](https://mathworks.com/help/parallel-computing/batch.html).

```matlab
% Create and submit a job to the cluster
job = batch( ...
    c, ... % cluster object created using parcluster
    @sqrt, ... % function/script to run
    1, ... % number of output arguments
    {[64 100]}); % input arguments

% Your MATLAB session is now available to do other work, such
% as create and submit more jobs to the cluster. You can also
% shut down your MATLAB session and come back later - the work
% will continue running on the cluster. Once you've recreated
% the cluster object using parcluster, you can view existing
% jobs using the Jobs property on the cluster object.

% Wait for the job to complete. If the job is already complete,
% this will return immediately.
wait(job);

% Retrieve the output arguments for each task. For this example,
% results will be a 1x1 cell array containing the vector [8 10].
results = fetchOutputs(job)
```

### Submit Work for Batch Processing with a Parallel Pool

You can use the `batch` command to create a parallel pool by using the `'Pool'` name-value pair argument.

```matlab
% Create and submit a batch pool job to the cluster
job = batch(
    c, ... % cluster object created using parcluster
    @sqrt, ... % function/script to run
    1, ... % number of output arguments
    {[64 100]}, ... % input arguments
    'Pool', 3); ... % use a parallel pool with three workers
```

Once the first worker has started running on the Kubernetes cluster, the worker will wait up to the number of seconds specified in `cluster.AdditionalProperties.Timeout` (default 600 seconds) for the remaining workers to start running before failing.
If your cluster does not have enough resources to start all of the workers before the timeout, your batch pool job will fail.
In this case, use fewer workers for your batch pool job, increase the timeout, or wait until your Kubernetes cluster has more resources available.

### Open an Interactive Parallel Pool

A parallel pool (parpool) is a group of MATLAB workers that you can interactively run work on.
Parallel pools are only supported if the Kubernetes cluster is running on the same network as your computer.
When you run the `parpool` command, MATLAB will submit a special job to the cluster to start the workers.
Once the workers have started, your MATLAB session will connect to them.
For more information about parpools, see the documentation for the [parpool command](https://mathworks.com/help/parallel-computing/parpool.html).

```matlab
% Open a parallel pool on the cluster. This command will return
% once the pool is opened.
pool = parpool(c);

% List the hosts the workers are running on. For a small pool,
% all the workers will likely be on the same machine. For a large
% pool, the workers will be spread over multiple nodes.
future = parfevalOnAll(p, @getenv, 1, 'HOST')
wait(future);
fetchOutputs(future)

% Output the numbers 1 to 10 in a parallel for (parfor) loop.
% Unlike a regular for loop, iterations of the loop will not
% be executed in order.
parfor idx = 1:10
    disp(idx)
end

% Use the pool to calculate the first 500 magic squares.
parfor idx = 1:500
    magicSquare{idx} = magic(idx);
end
```

## License

The license is available in the [license.txt](license.txt) file in this repository.

## Community Support

[MATLAB Central](https://www.mathworks.com/matlabcentral)

## Technical Support

If you require assistance or have a request for additional features or capabilities, please contact [MathWorks Technical Support](https://www.mathworks.com/support/contact_us.html).

Copyright 2022-2023 The MathWorks, Inc.
