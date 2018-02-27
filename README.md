## GCLOUD GPU 

1. [TLDR; Run two lines of code and you're done (almost)](#tldr)
2. [Create Instance Script](#create)
3. [Instance Setup Script](#setup)
4. [Almost: The rest of the setup](#almost)

---

<a name="tldr">

### TLDR;

##### TLDR; TLDR;

```bash
# from local computer
. create_instance.sh gpu-84 4 500

# from remote instance
. instance-setup.sh
```

##### SLIGHTLY MORE DETAIL

LOCAL COMPUTER:

```bash
# example: create instance named gpu-84 with 4 GPUs 500GB of memory 
. create_instance.sh gpu-84 4 500
```


```bash
# example: copy setup script to remote instance named gpu-84
gcloud compute scp instance-setup.sh gpu-84:~/
```

```bash
# example: ssh into instance named gpu-84
gcloud compute ssh gpu-84

# --OR-- using alias (https://github.com/brookisme/gcloud_gpu/wiki/Local-Setup#gcloud_alias)
gssh gpu-84
```

REMOTE INSTANCE:

```bash
# example: run setup script installing TensorFlow from pip
. instance-setup.sh

# --OR-- example: run setup script installing TensorFlow later from sources (https://github.com/brookisme/gcloud_gpu/wiki/TensorFlow:-Install-from-Sources)
. instance-setup.sh gpu skip-tf
```


---

<a name="create">

### CREATE INSTANCE

Use the script [create_instance.sh](https://github.com/brookisme/gcloud_gpu/blob/master/create_instance.sh) to create new instances.

USAGE:

```bash
. create_instance.sh \
    <NAME> \
    <COUNT> \
    [DISK_SIZE: 200] \
    [SNAPSHOT_NAME: No snapshot]
```

VARS:

- NAME: (required) name of instance
- COUNT: (required) GPUs -1,2,4 | CPUs 0
- DISK_SIZE: 
    - defaluts to 200 (GB) 
    - consider of decreasing consider [adding a persistent disk](#pdisk)
    
- SNAPSHOT_NAME (_see note below_): 
    - must first create snapshot (see above note)
    - DISK_SIZE is ignored so pass in anything as a space filler (like "skip" in example below)


EXAMPLES:

```bash
# 4 gpu, default disk size (200GB)
. create_instance.sh gpu-84 4

# 4 gpu, from snapshot
. create_instance.sh gpu-84-snapshot-name 4 skip snapshot_name
```


 **NOTE ON SNAPSHOTS:** If creating instance from a snapshot you must first  create the disk

```bash
gcloud compute disks create DISK_NAME --source-snapshot SNAPSHOT_NAME
```


---

<a name="setup">

### INSTANCE SETUP

Use the script [instance-setup.sh](https://github.com/brookisme/gcloud_gpu/blob/master/instance-setup.sh) to setup new instances.


##### Copy setup script to instance

```bash
gcloud compute scp instance-setup.sh <INSTANCE_NAME>:~/
```


##### Run setup script

**NOTE:** The Anaconda install is interactive. The default for add anaconda to PATH is no -- **type yes!!!**

You can choose to install with TensorFlow or, if you are going to [install from sources](https://github.com/brookisme/gcloud_gpu/wiki/TensorFlow:-Install-from-Sources-Notes), skip the tensorflow installs. You also have the option of skipping the "geo tools" listed [here](https://github.com/brookisme/gcloud_gpu/wiki/Install-List#py3).

```bash
# CPU (with TF)
. instance-setup.sh cpu

# GPU (with TF)
. instance-setup.sh

# GPU (without TF)
. instance-setup.sh gpu skip-tf

# GPU (without TF or GEO-tools)
. instance-setup.sh gpu skip-tf skip-geo

# GPU (including TF but without GEO-tools)
. instance-setup.sh gpu tf skip-geo
```


---

<a name="almost">

### THE REST

There are still a small handful of steps (most of which are optional).

Required:

- [GPU Setup](https://github.com/brookisme/gcloud_gpu/wiki/GPU-Setup)
- [IP Config](https://github.com/brookisme/gcloud_gpu/wiki/Instance-Setup#ip)

[Optional](https://github.com/brookisme/gcloud_gpu/wiki/Instance-Setup):

REMOTE INSTANCE:

- [TMUX](https://github.com/brookisme/gcloud_gpu/wiki/Instance-Setup#tmux)
- [Pretty Prompt](https://github.com/brookisme/gcloud_gpu/wiki/Instance-Setup#prompt)
- [Jupyter-PWD](https://github.com/brookisme/gcloud_gpu/wiki/Instance-Setup#jupyter)

[LOCAL COMPUTER](https://github.com/brookisme/gcloud_gpu/wiki/Local-Setup): 

- [GCloud Aliases](https://github.com/brookisme/gcloud_gpu/wiki/Local-Setup#gcloud_alias)
- [Sublime-SFTP and Sublime-Remote](https://github.com/brookisme/gcloud_gpu/wiki/Local-Setup#subl_sftp)

Also consider [installing TensorFlow from sources](https://github.com/brookisme/gcloud_gpu/wiki/TensorFlow:-Install-from-Sources-Notes).





 