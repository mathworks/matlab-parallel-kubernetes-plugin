# Parallel Computing Toolbox Plugin for MATLAB Parallel Server with Kubernetes

[![View Plugin for MATLAB Parallel Server with Kubernetes on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://mathworks.com/matlabcentral/fileexchange/120243-plugin-for-matlab-parallel-server-with-kubernetes)

Parallel Computing Toolbox&trade; provides the `Generic` cluster type for submitting MATLAB&reg; jobs to a cluster running a third-party scheduler.
The `Generic` type uses a set of plugin scripts to define how your machine communicates with your scheduler.
You can customize the plugin scripts to configure how MATLAB interacts with the scheduler to best suit your cluster setup and support custom submission options.

This repository contains MATLAB code files and shell scripts that you can use to submit jobs from a MATLAB or Simulink session running on Windows&reg;, Linux&reg;, or macOS operating systems to a Kubernetes&reg; cluster.

The following instructions are in two sections.
The first section describes how to prepare the Kubernetes cluster to run MATLAB Parallel Server workers.
To configure the Kubernetes cluster for MATLAB Parallel Server as cluster administrator see [One-Time Cluster Setup Instructions](#one-time-cluster-setup-instructions-cluster-administrators).

The second section describes how to integrate Parallel Computing Toolbox installed on your computer with the Kubernetes cluster.
To use MATLAB Parallel Server workers on the Kubernetes cluster as MATLAB users see [Cluster Profile Creation Instructions](#cluster-profile-creation-instructions).

## Usage Notes and Limitations

### Shared Job Storage Location Requirement

MATLAB Parallel Server with Kubernetes requires your computer and the Kubernetes cluster to have read and write access to a shared folder.
You must make this folder available to the cluster via a Kubernetes PersistentVolumeClaim.

### Cluster Access Requirement

MATLAB Parallel Server with Kubernetes requires your computer to have access to the cluster via Kubectl.
You must have the ability to get, list, create and delete Kubernetes pods, jobs and secrets.

### Limitations

Interactive parallel pools are not supported for remote Kubernetes clusters, such as a cluster running in the cloud.
You can only use interactive parallel pools if your Kubernetes cluster is running on the same network as your computer.

## One-Time Cluster Setup Instructions (Cluster Administrators)

The instructions in this section are for Kubernetes cluster administrators to prepare the cluster to run MATLAB Parallel Server workers.
Before proceeding, ensure that you have the products required for one-time cluster setup in the [Products Required](### Products Required for Cluster Setup) section.

### Products Required for Cluster Setup

- Kubernetes version 1.21 or later running on the cluster. For help configuring Kubernetes on your cluster, see [https://kubernetes.io](https://kubernetes.io/).
- Docker installed on your computer. For help with installing Docker, see [https://docs.docker.com/get-docker](https://docs.docker.com/get-docker/).
- Kubectl installed on your computer. For help with installing Kubectl, see [https://.kubernetes.io/docs/tasks/tools](https://kubernetes.io/docs/tasks/tools/).

### Setup instructions

#### 1. Download or Clone this Repository

To download a ZIP archive of this repository, at the top of this repository page, select **Code > Download ZIP**.
Alternatively, to clone this repository to your computer with Git software, enter this command at your system command line:
```
git clone https://github.com/mathworks/matlab-parallel-kubernetes-plugin
```

#### 2. Create Kubernetes Namespace and Limit Resources

Kubernetes uses namespaces to separate groups of resources.
For more information, see the documentation for [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) on the Kubernetes website.
Run MATLAB Parallel Server jobs inside a specific namespace on your cluster so that the jobs are separate from other resources on the cluster.

If users do not specify a custom namespace in the cluster profile, MATLAB Parallel Server workers run in a namespace called `matlab`.
The workers attempt to create the `matlab` namespace if it does not already exist.
If the workers cannot create the `matlab` namespace, the workers run in the `default` namespace.

To create a custom namespace with the name `my-namespace`, run this command:
```
kubectl create namespace my-namespace
```

##### Limit Kubernetes Pods in Namespace

You can limit the number of pods that run simultaneously in a namespace.
Each MATLAB Parallel Server worker requires one pod.
By limiting pods, you can limit the number of MATLAB Parallel Server workers that run simultaneously.
If your MATLAB Parallel Server license has fewer than 200 workers, limit the number of pods to the number of MATLAB Parallel Server workers by running this command:
```
kubectl create resourcequota quota-name --namespace my-namespace --hard pods=numWorkers
```
`quota-name` is the name of the resource quota, `my-namespace` is the namespace, and `numWorkers` is the number of MATLAB Parallel Server workers on your license.

#### 3. Set Up PersistentVolumeClaim for Job Storage

You must ensure that each MATLAB Parallel Server user has read and write access to a folder on their computer that is shared with the cluster via a PersistentVolumeClaim.
The account the user uses to run jobs the cluster must also have read and write access to that folder.

You can create a Kubernetes PersistentVolumeClaim either statically from a PersistentVolume or dynamically from a StorageClass.
For more information, see the documentation for [PersistentVolume](https://https://kubernetes.io/docs/concepts/storage/persistent-volumes/) on the Kubernetes website.

For example, if you have an on-premise Kubernetes cluster, you can create a PersistentVolume from an NFS server that is visible to your cluster.
Alternatively, if you have a Kubernetes cluster in AWS, you can create a StorageClass to provision storage from an EFS instance.
For details, see the documentation for [Amazon EFS CSI Driver](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html) on the AWS&reg; website.
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
`<pvc-name>` is the PersistentVolumeClaim name and `<capacity>` is the amount of storage you want to provision for your job storage location.
For information on the units you can use for storage capacity, see the documentation for [Resource Management for Pods and Containers](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) on the Kubernetes website.
If you are using a PersistentVolume, set `<pv-name>` to the name of the PersistentVolume and `<storage-class-name>` to `""`.
If you are using a StorageClass for dynamic provisioning, omit the `volumeName` field and set `<storage-class-name>` to the name of the StorageClass.

#### 4. (Optional) Share MATLAB and MATLAB Parallel Server Installation with Cluster

The cluster must have access to a MATLAB and MATLAB Parallel Server installation.
You can build this into the Docker image (see step 5) or use your own MATLAB and MATLAB Parallel Server installation.
To share your own MATLAB and MATLAB Parallel Server installation with the cluster, create a PersistentVolumeClaim that contains the installation.

#### 5. Build Docker Image for MATLAB Parallel Server on Cluster

To run MATLAB Parallel Server workers on the Kubernetes cluster, you must build a suitable Docker image using the Dockerfile included in this repository and make it available on the cluster.

To build the image, first navigate to the `image/` folder inside this repository.

When building, you must specify a MATLAB release version.
This version must match the version of MATLAB installed on the computers of the MATLAB Parallel Server users.

If you are sharing your own MATLAB and MATLAB Parallel Server installation with the cluster (see step 4), follow Option 1. Otherwise, follow Option 2.

##### Option 1: Build Docker Image Without MATLAB Installed
To build a Docker image without a built-in MATLAB installation, specify a MATLAB release number with a lowercase "r".
For example, to build a docker image with MATLAB release R2022a and the image name `image-name`, run this command from within the `image/` folder:
```
docker build . -t image-name --build-arg MATLAB_RELEASE=r2022a
```

##### Option 2 (Linux): Build Docker Image with MATLAB Installed
To build a Docker image with a built-in MATLAB and MATLAB Parallel Server installation, set the `INSTALL_MATLAB` argument to `true`. You can use this option only when you build the Docker image on a Linux machine.

To build the image, run this command from within the `image/` folder:
```
docker build . -t image-name --build-arg MATLAB_RELEASE=release --build-arg INSTALL_MATLAB=true --build-arg LICENSE_SERVER=port@hostname ADDITIONAL_PRODUCTS="Product1 Product2"
```

By default, this command installs all MATLAB toolboxes included with a MATLAB Parallel Server license.
These toolboxes are listed for each release in files under `image/product_lists`.
To modify the toolboxes to install, edit the file corresponding to your desired MATLAB release before running the `docker build` command.
The toolbox names must match the product names listed on the MathWorks&reg; product page with any spaces replaced by underscores.
For a full list of product names, see the page for [Products](https://www.mathworks.com/products.html) on the MathWorks website.

After you have built the image, you must make it available on your Kubernetes cluster.
You can host it in a remote repository or pull the image to each node to obtain a local copy.

#### 6. Restrict Access to Kubernetes Secrets for Online Licensing

MATLAB online licensing sends login tokens to the Kubernetes pods via Kubernetes secrets.
If you use MATLAB online licensing, enable encryption at rest and restrict access to use Kubernetes secrets safely.
For more information, see the documentations for [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) on the Kubernetes website.

## Cluster Profile Creation Instructions

The instructions in this section are for MATLAB users to integrate their Parallel Computing Toolbox with the Kubernetes cluster.
For help with the following instructions, contact your cluster administrator.
Before proceeding, ensure that you have the products required for running MATLAB Parallel Server with Kubernetes listed in the [Products Required for Cluster Profile Creation](### Products Required for Cluster Profile Creation) section.

### Products Required for Cluster Profile Creation

- MATLAB and Parallel Computing Toolbox R2019b or newer installed on your computer. For an overview of these software products, see the product pages for [MATLAB](https://mathworks.com/products/matlab.html) and [Parallel Computing Toolbox](https://mathworks.com/products/parallel-computing.html) on the MathWorks website. 
For help with installing MATLAB or Parallel Computing Toolbox, see MathWorks install support: [www.mathworks.com/help/install](https://mathworks.com/help/install/index.html).
- A MATLAB Parallel Server&trade; license. For an overview, see the product page for [MATLAB Parallel Server](https://mathworks.com/products/matlab-parallel-server.html) on the MathWorks website.
- Kubectl installed on your computer. For help with installing Kubectl, see [https://.kubernetes.io/docs/tasks/tools](https://kubernetes.io/docs/tasks/tools/).
- Helm&reg; installed on your computer. For help with installing Helm, see [https://helm.sh/docs/intro/quickstart](https://helm.sh/docs/intro/quickstart/)


### Setup instructions

#### 1. Set Up Access to Kubernetes Cluster from Your Computer

You must have access to the Kubernetes cluster from your computer via the Kubectl command line tool.
The access method is dependent on the cluster.
For example on a Linux machine, you can install Kubectl and Helm software using the distribution's package manager and modify the `~/.kube/config` file to access the cluster.
For help with configuring your machine to access the cluster, contact your cluster administrator.

#### 2. Download or Clone this Repository
To download a ZIP archive of this repository, at the top of this repository page, select **Code > Download ZIP**.
Alternatively, to clone this repository to your computer with Git software, enter this command at your system command line:
```
git clone https://github.com/mathworks/matlab-parallel-kubernetes-plugin
```
You can execute this command from the MATLAB Command Prompt by adding `!` before the command.

#### 3. Create Cluster Profile

Create a cluster profile by using the Cluster Profile Manager or the MATLAB Command Window.

To open the Cluster Profile Manager, on the **Home** tab, in the **Environment** section, select **Parallel > Create and Manage Clusters**.
In the Cluster Profile Manager, select **Add Cluster Profile > Generic** from the menu to create a new `Generic` cluster profile.

Alternatively, create a new `Generic` cluster object by entering this command in the MATLAB Command Window:
```matlab
c = parallel.cluster.Generic;
```

#### 4. Configure Cluster Properties

This table lists the properties that you must specify to configure the Generic cluster profile.
For a full list of cluster properties, see the documentation for [`parallel.Cluster`](https://mathworks.com/help/parallel-computing/parallel.cluster.html) on the MathWorks website.

**Property**            | **Description**
------------------------|----------------
`JobStorageLocation`    | Folder in which your machine stores job data.
`NumWorkers`            | Number of workers available on your cluster. Set this property to a value no greater than the number of workers your license allows or the total number of CPUs available on your cluster.
`OperatingSystem`       | 'unix'
`PluginScriptsLocation` | Full path to the folder containing this file.

These cluster properties are optional:

**Property**                 | **Value**
-----------------------------|----------------
`RequiresOnlineLicensing`    | Set this property to `true` to use online licensing for MATLAB Parallel Server.
`LicenseNumber`              | License number of your MATLAB Parallel Server license. Set this property only if your MathWorks account is associated with more than one MATLAB Parallel Server license.
`NumThreads`                 | Number of computational threads to use on each worker (default: 1). Set this to a value no greater than the maximum number of CPUs available on a single node in your cluster.

In the Cluster Profile Manager, set each property value.
Alternatively, at the MATLAB Command Window, set properties on the cluster object using dot notation:
```matlab
c.JobStorageLocation = '/data/matlabJobs';
% etc.
```

At the MATLAB Command Window, you can also set properties when you create the `Generic` cluster object by using name-value arguments. For example, this code configures a Generic cluster object with 20 workers for the specified job storage location, cluster MATLAB root, operating system, and plugin scripts location. 
```matlab
c = parallel.cluster.Generic( ...
    'JobStorageLocation', '/data/matlabJobs', ...
    'NumWorkers', 20, ...
    'OperatingSystem', 'unix', ...
    'PluginScriptsLocation', '/data/MatlabKubernetesPlugin');
```

#### 5. Get User ID and Group ID on Cluster

To allow the MATLAB Parallel Server workers to write to your job storage location on the cluster, you must provide the user ID and group ID of your account on the cluster.

If you know the hostname of one of the node machines and your username on that machine, you can use the `getClusterIDs` function provided with the plugin scripts to get your user ID and group ID.

In MATLAB, navigate to the folder containing the Kubernetes plugin scripts.
If you have a password to log into the machine, run this command at the MATLAB Command Window and enter the password when MATLAB prompts you:
```matlab
getClusterIDs(hostname, username);
```
If you have access to the cluster via an identity file that does not require a password, run this command in the Command Window:
```matlab
getClusterIDs(hostname, username, 'IdentityFile', filename);
```
`filename` is the path to the identity file.
If you have access to the cluster via an identity file that requires a password, run this command in the Command Window and enter the password when MATLAB prompts you:
```matlab
getClusterIDs(hostname, username, 'IdentityFile', filename, 'IdentityFileHasPassword', true);
```

All authentication modes supported by `RemoteClusterAccess` are supported.
For more information, see the documentation for [`RemoteClusterAccess`](https://mathworks.com/help/parallel-computing/remoteclusteraccess.html) on the MathWorks website.

#### 6. Configure Additional Properties

You can use the `AdditionalProperties` table of the cluster profile to set additional properties. Use this table to modify the behavior of the `Generic` profile without editing the plugin scripts.
By modifying the plugin properties, you can add support for your own custom additional properties.

You can set additional properties in the cluster profile. In the Cluster Profile Manager, click on the `Generic` profile that you want to modify. Click **Edit** at the bottom-right. To add a new property, go to the` AdditionalProperties` table and click **Add**.
Alternatively, you can set additional properties programmatically by accessing the `AdditionalProperties` table of the `Generic` cluster object. In the Command Window, use dot notation to add new rows to the `AdditionalProperties` table. For example:

```matlab
c.AdditionalProperties.Image = 'imageName';
```

You must specify these `AdditionalProperties`:

**Property Name**           | **Data Type** | **Description**
----------------------------|---------------|----------------
`Image`                     | `String`      | Name of the Docker image or (URL, if you are hosting the image remotely).
`ImagePullPolicy`           | `String`      | Image availability. If the image is available locally on the cluster, set this property to `"Never"`. If you are hosting the image remotely, set this property to `"Always"`.
`JobStoragePVC`             | `String`      | Name of the PersistentVolumeClaim to use for storing job data.
`JobStoragePath`            | `String`      | Path to the folder to use for storing job data within the PersistentVolume.
`ClusterUserID`             | Numeric       | ID of your user account on the cluster.
`ClusterGroupID`            | Numeric       | Group ID of your user account on the cluster.

If the cluster shares a MATLAB and MATLAB Parallel Server installation via a PersistentVolumeClaim, set these additional properties:

**Property Name**         | **Data Type** | **Description**
--------------------------|---------------|----------
`MatlabPVC`               | `String`      | Name of the PersistentVolumeClaim containing the MATLAB and MATLAB Parallel Server installation.
`MatlabPath`              | `String`      | Path to the MATLAB installation within the PeristentVolume.

These additional properties are optional:

**Property Name**         | **Data Type** | **Description**
--------------------------|---------------|----------------
`Namespace`                 | `String`   | Kubernetes namespace. If you do not specify this property, MATLAB uses the `matlab` namespace. If MATLAB cannot create the `matlab` namespace, the workers run in the `default` namespace.
`KubeConfig`                | `String`   | Location of the `config` file that `kubectl` uses to access your cluster. For more information, see the documentation for the [Kubernetes `config` file](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/) on the Kubernetes website. If you do not specify this property, MATLAB uses the default location (`$HOME/.kube/config`).
`KubeContext`               | `String`   | Context within your Kubernetes `config` file if that file has multiple clusters or user configurations. For more information, see the documentation for [Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) on the Kubernetes website. If you do not set this property, MATLAB uses the default context.
`LicenseServer`             | `String`   | Port and hostname of a machine running a Network License Manager in the format `port@hostname`.
`Timeout`                   | Numeric   | Time in seconds that MATLAB waits for all worker pods to start running after the first worker starts in a pool or SPMD job. The default value is 600. 

#### 7. Save New Profile

In the Cluster Profile Manager, click **Done**.
If you are setting the additional properties programmatically, in the Command Window run this command:
```matlab
saveAsProfile(c, "myKubernetesCluster");
```
Your cluster profile is now ready to use.

#### 8. Validate Cluster Profile

Cluster validation submits a job of each type to test whether the cluster profile is configured correctly.
If your Kubernetes cluster is running on a different network to your computer, such as in the cloud, unselect the "Parallel pool test" check box.
In the Cluster Profile Manager, click the **Validate** button.
All stages must pass successfully (except the "Parallel pool test" stage if you have a remote cluster).
If you make a change to the cluster profile, run cluster validation to ensure your changes cause no errors.
You do not need to validate the profile each time you use it or each time you start MATLAB.

#### Debug Cluster Validation Issues

If cluster validation fails, you can investigate using the `inspectPods` function provided in the same folder as the plugin scripts.
First, create a job object to use to debug.
For example, to create and submit an independent job, run this command:
```matlab
c = parcluster("myKubernetesCluster");
job = createJob(c);
createTask(job, @plus, 1, {1, 1});
submit(job);
```

To inspect the status of the Kubernetes pods associated with the job, navigate to the plugin script location in the MATLAB Command Window and run this command:
```matlab
inspectPods(job);
```
This command displays the states of the Kubernetes pods associated with that job.

To obtain further information on a specific pod corresponding to a single task of a job, get the task object by indexing `job.Tasks`.
To get the first task, for example, run this command:
```matlab
task = job.Tasks(1);
```

To display detailed information about the Kubernetes pod corresponding to that task, run this command:
```matlab
inspectPods(task);
```

For help understanding the displayed information, contact your cluster administrator.

## Examples

Create a cluster object using your profile:
```matlab
c = parcluster("myKubernetesCluster")
```

### Submit Work for Batch Processing

The `batch` command runs a MATLAB script or function on a worker on the cluster.
For more information about batch processing, see the documentation for [batch](https://mathworks.com/help/parallel-computing/batch.html) on the MathWorks website.

```matlab
% Create a job and submit it to the cluster
job = batch( ...
    c, ... % Cluster object created using parcluster
    @sqrt, ... % Function or script to run
    1, ... % Number of output arguments
    {[64 100]}); % Input arguments

% Your MATLAB session is now available to do other work You can
% continue to create and submit more jobs to the cluster. You can also
% shut down your MATLAB session and come back later. The work
% continues to run on the cluster. After you recreate
% the cluster object using the parcluster function, you can view existing
% jobs using the Jobs property of the cluster object.

% Wait for the job to complete. If the job is already complete,
% MATLAB does not block the Command Window and this command 
returns the prompt (`>>`) immediately.
wait(job);

% Retrieve the output arguments for each task. For this example,
% % the output is a 1x1 cell array containing the vector [8 10].
results = fetchOutputs(job)
```

### Submit Work for Batch Processing with a Parallel Pool

You can use the `batch` command to create a parallel pool by using the `'Pool'` name-value pair argument.

```matlab
% Create and submit a batch pool job to the cluster
job = batch(
    c, ... % Cluster object created using parcluster
    @sqrt, ... % Function/script to run
    1, ... % Number of output arguments
    {[64 100]}, ... % Input arguments
    'Pool', 3); ... % Use a parallel pool with three workers
```

Once the first worker has started running on the Kubernetes cluster, the worker waits for the number of seconds specified in the `cluster.AdditionalProperties.Timeout` property (default of 600 seconds) for the remaining workers to start running before the batch pool job fails.
If your cluster does not have enough resources to start all the workers before the timeout, your batch pool job fails.
To resolve the issue, use fewer workers for your batch pool job, increase the timeout, or wait until your Kubernetes cluster has more resources available.

### Open an Interactive Parallel Pool

A parallel pool (parpool) is a group of MATLAB workers on which you can interactively run work.
When you run the `parpool` command, MATLAB submits a special job to the cluster to start the workers.
Once the workers start, your MATLAB session connects to them.
For more information about parpools, see the documentation for [parpool](https://mathworks.com/help/parallel-computing/parpool.html) on the MathWorks website.

```matlab
% % Open a parallel pool on the cluster. This command
% returns the prompt (>>) once the pool is opened.
pool = parpool(c);

% List the hosts on which the workers are running. For a small pool,
% all the workers are typically on the same machine. For a large
% pool, the workers are usually spread over multiple nodes.
future = parfevalOnAll(p, @getenv, 1, 'HOST')
wait(future);
fetchOutputs(future)

% Output the numbers 1 to 10 in a parallel `for`-loop.
% Unlike a regular `for`-loop, the software does not 
execute iterations of the loop in order.
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
