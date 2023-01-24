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
You must either make this directory available via an NFS server or mount it on each node of the cluster.

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

#### 2. Set up a Job Storage Location

You must ensure that each MATLAB Parallel Server user has read and write access to a directory on their computer that is shared with the cluster.
The account the user has access to on the cluster must also have read and write access to that directory.
To share the job storage location with the cluster, select from these options:

1. Make the directory available via an NFS server that is accessible to the cluster.
For example, you could create your own NFS server or use an Amazon EFS instance.
With this option, you do not need to mount to the cluster yourself.
Share the server hostname and the location of the directory within the server with each user.

2. Manually mount the directory on each node of the cluster.
You must use the same location on each node, although the shared directory can be a different location on the user's computer.
Share the location of the directory on the nodes with each user.

#### 3. (Optional) Share your own MATLAB and MATLAB Parallel Server Installation with the Cluster

The cluster must have access to a MATLAB and MATLAB Parallel Server installation.
You can either build this into the Docker image (see step 4) or use your own MATLAB and MATLAB Parallel Server installation.
To share your own MATLAB and MATLAB Parallel Server installation with the cluster, select from these options:

1. Make the directory containing your MATLAB and MATLAB Parallel Server installation available via an NFS server that is accessible to the cluster.
With this option, you do not need to mount to the cluster yourself.
Share the server hostname and the location of the directory within the server with each user.

2. Manually mount the directory containing your MATLAB and MATLAB Parallel Server installation on each node of the cluster.
You must use the same location on each node.
Share the location of the directory on the nodes with each user.

#### 4. Build the Docker Image for MATLAB Parallel Server on the Cluster

To run MATLAB Parallel Server workers on the Kubernetes cluster, you must build a suitable Docker image using the Dockerfile included in this repository and make it available on the cluster.

To build the image, first navigate to the `image/` directory inside this repository.

When building, you must specify a MATLAB release number.
This must match the version of MATLAB installed on the computers of the MATLAB Parallel Server users.

If you are sharing your own MATLAB and MATLAB Parallel Server installation with the cluster (see step 3), follow Option 1. Otherwise, follow Option 2.

##### Option 1: Build the Docker Image for a Mounted MATLAB Installation
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

#### 5. Create a Kubernetes Namespace and Limit Its Resources

Kubernetes namespaces are used to separate groups of resources.
For more information, see the [Kubernetes namespace documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/).
It is recommended that you run MATLAB Parallel Server jobs inside a specific namespace on your cluster so that they are separate from other resources on the cluster.

If users do not specify a custom namespace in the cluster profile, MATLAB Parallel Server workers will attempt to run in a namespace called "matlab".
MATLAB will attempt to create the "matlab" namespace if it does not already exist.
If this namespace cannot be created, the workers will run in the "default" Kubernetes namespace.

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

#### 6. Restrict Access to Kubernetes Secrets if Using Online Licensing

MATLAB online licensing sends login tokens to the Kubernetes pods via Kubernetes secrets.
If you use MATLAB online licensing, enable encryption at rest and restrict access to safely use Kubernetes secrets.
For more information, see the [Kubernetes secret documentation](https://kubernetes.io/docs/concepts/configuration/secret/).

#### 7. (Optional) Install Helm and Kubectl Executables on the Cluster

Pool and SPMD jobs require access to the Helm and Kubectl executables on the cluster as well as on each user's computer.
The Docker image contains the latest versions of these executables by default.
If these versions are incompatible with your Kubernetes cluster, install your own versions of these executables on the cluster.
The executables must be installed at the same location on each node.

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
ClusterMatlabRoot     | If the cluster administrator chose to share a MATLAB and MATLAB Parallel Server installation via an NFS server, use the location of the installation on the server. If the cluster administrator mounted a MATLAB and MATLAB Parallel Server installation on each cluster node, use the location at which it is mounted. If the cluster administrator installed MATLAB and MATLAB Parallel Server on the Docker image, leave this blank.
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
    'ClusterMatlabRoot', '/usr/local/matlab', ...
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
ClusterJobStorageLocation | String   | Location where job data is stored on the cluster. If the cluster administrator shared the job storage directory via an NFS server, use the location of the directory on the server. If the cluster administrator mounted this directory on each cluster node, use the location at which it is mounted.
ClusterUserID             | Number   | The ID of your user account on the cluster.
ClusterGroupID            | Number   | The group ID of your user account on the cluster.

If the cluster administrator chose to share a MATLAB and MATLAB Parallel Server installation with the cluster rather than installing MATLAB and MATLAB Parallel Server on the Docker image, set the following additional property in addition to setting the `ClusterMatlabRoot` property:

**Property Name**         | **Type** | **Value**
--------------------------|----------|----------
MountMatlab               | Logical  | true

If the cluster administrator chose to share a MATLAB and MATLAB Parallel Server installation via an NFS server, set the following additional property:

**Property Name**         | **Type** | **Value**
--------------------------|----------|----------------
MatlabServer              | String   | Hostname or IP address of the NFS server from which the MATLAB installation is shared.

If the cluster administrator chose to share the job storage location via an NFS server, set the following additional property:

**Property Name**         | **Type** | **Value**
--------------------------|----------|----------------
JobStorageServer          | String   | Hostname or IP address of the NFS server from which the job storage location is shared.

The following additional properties are optional:

**Property Name**         | **Type** | **Description**
--------------------------|----------|----------------
Namespace                 | String   | The Kubernetes namespace to use. If this property is not specified, the cluster will use the `'matlab'` namespace. If the `'matlab'` namespace cannot be created, the `'default'` namespace is used instead.
KubeConfig                | String   | The location of the config file used by `kubectl` to access your cluster. For more information, see the [Kubernetes config file documentation](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/). If this property is not specified, the default location (`$HOME/.kube/config`) is used.
KubeContext               | String   | The context within your Kubernetes config file to use if you have multiple clusters or user configurations within that file. For more information, see the [Kubernetes context documentation](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/). If this property is not specified, the default context is used.
LicenseServer             | String   | The port and hostname of a machine running a Network License Manager in the format port@hostname.
Timeout                   | Number   | The amount of time in seconds that MATLAB waits for all worker pods to start running after the first worker starts in a pool or SPMD job. By default, this property is set to 600 seconds.

If the cluster administrator installed specific versions of the Helm and Kubectl executables on the cluster, set the following additional properties:

**Property Name**         | **Type** | **Description**
--------------------------|----------|----------------
HelmDir                   | String   | Directory on the Kubernetes cluster in which the Helm executable is installed.
KubectlDir                | String   | Directory on the Kubernetes cluster in which the Kubectl executable is installed.

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

Copyright 2022 The MathWorks, Inc.
