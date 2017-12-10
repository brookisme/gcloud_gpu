## GCLOUD GPU 

_The number of virtual CPUs and the storage have little effect on cost. However prices increase dramatically with GPUs_

- n1-standard-8: 8 virtual CPUs and 30 GB of memory.
- boot-disk-size: 200GB
- count (# of GPUs):
	- 0 [CPU]: ~ $0.28 / hour
	- 1: ~ $0.98 / hour
	- 2: ~ $1.68 / hour
	- 4: ~ $3.08 / hour


---------
&nbsp;
## CREATE INSTANCE

Use the script [create_instance.sh](https://github.com/brookisme/gcloud_gpu/blob/master/create_instance.sh) to create new instances.

USAGE:

```bash
. create_instance.sh \
    <NAME> \
    <COUNT> \
    [DISK_SIZE: 20] \
    [SNAPSHOT_NAME: No snapshot]
```

VARS:

- NAME: (required) name of instance
- COUNT: (required) GPUs -1,2,4 | CPUs 0
- DISK_SIZE: 
    - defaluts to 20 (GB)
    - instead of increasing consider [adding a persistent disk](#pdisk)
    
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

<a name='pdisk'></a>
###### ADD PERSISTENT DISK
https://cloud.google.com/compute/docs/disks/add-persistent-disk

```bash
# create/attach disk
gcloud compute disks create <DISK_NAME> --size 200 --type pd-standard
gcloud compute instances attach-disk <INSTANCE_NAME> --disk <DISK_NAME>

#
# format/mount disk (ssh to instance)
#

# get DISK_ID (~sdb)
sudo lsblk 

# format disk
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/<DISK_ID>

# mount disk at "/data"
sudo mkdir /data
sudo mount -o discard,defaults /dev/<DISK_ID> /data
```


###### CPU (from gpu snapshot) 

If you are creating a CPU from a GPU snapshot you'll need to remove the GPU dependencies.

```bash
# remove cuda
rm -rf ~/cuda
rm -rf NVIDIA_CUDA-8.0_Samples
sudo rm -rf /usr/local/cuda
conda uninstall cuda80

# tensorflow
TF=https://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-1.1.0-cp36-cp36m-linux_x86_64.whl
pip install --ignore-installed --upgrade $TF

# theano: 
# - update .theanorc
# -- update [global]
device = cpu
# --remove [cuda]

# .bashrc -- remove from PATH
# export CUDA_HOME=/usr/local/cuda-8.0 
# export LD_LIBRARY_PATH=$CUDA_HOME/lib64
# PATH=$CUDA_HOME/bin:$PATH 
# export PATH
```


---------
&nbsp;
## SETUP SCRIPT

##### copy files to instance

```bash
gcloud compute copy-files gpu-setup.sh gpu-84:~/
```


##### SET UP SCRIPT

**NOTE:** The Anaconda install is interactive. The default for add anaconda to PATH is no -- **type yes!!!**

```bash
# GPU
. gpu-setup.sh

# CPU
. gpu-setup.sh CPU
```


---------
&nbsp;
## INSTANCE SETUP 

###### CUDNN

After signing up you can download cudnn from here [https://developer.nvidia.com/rdp/cudnn-download](https://developer.nvidia.com/rdp/cudnn-download). I've saved a version to cloud-storage, which makes copying to a compute instance lightning fast.

**Tensorflow does not yet work with cudnn-v6, use v5 for now**

```bash
# download cudnn v5.1
wget https://storage.googleapis.com/bgw-public/cudnn/8.0/cudnn-8.0-linux-x64-v5.1.tgz

# unpack
tar zxvf cudnn-8.0-linux-x64-v5.1.tgz 

# move cuda to usr/local
sudo mv cuda/lib64/* /usr/local/cuda/lib64/
sudo mv cuda/include/* /usr/local/cuda/include/

# install samples
cuda-install-samples-8.0.sh  ~ 

# check cuda install
pushd NVIDIA_CUDA-8.0_Samples/1_Utilities/deviceQuery
make
./deviceQuery 
popd
```

###### EXTRENAL IP

- reserve a static ip [GCloud-Console > Networking > External IP](https://console.cloud.google.com/networking/addresses/list
)
- add a firewall rule [GCloud-Console > Networking > Firewall Rules](https://console.cloud.google.com/networking/firewalls/list
): 
	- (source ip-ranges) 0.0.0.0/0
	- (protocols and ports) tcp:8800-8900


###### OTHER POSSIBLE CHANGES:

- do not delete disk when deleted

###### JUPYTER 

```python
# set password  *** copy sha output ***
from notebook.auth import passwd
passwd()
```

```
jupyter notebook --generate-config

vi ~/.jupyter/jupyter_notebook_config.py 
# uncomment/update line
# c.NotebookApp.password = 'sha1...'
```

```
# full cmd
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser &

# alias in bashrc from gpu-setup.sh
jnb
```

###### GIT (password only every 12 hours)

```
git config --global credential.helper 'cache --timeout=43200'
```

###### GIT PRETTY PROMPT

I couldn't get this work in the gpu-setup so you'll have to add it to your .bashrc yourself

- colorizes prompt
- adds branch name if git repo
- colorizes branch name
    + green if clean branch
    + red if edits exist

```bash
# based on http://vvv.tobiassjosten.net/bash/dynamic-prompt-with-git-and-ansi-colors/
# - conda env added
# - colors changed

# Configure colors, if available.
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
  c_reset='\[\e[0m\]'
  c_user='\[\e[1;36m\]'
  c_path='\[\e[0;33m\]'
  c_git_clean='\[\e[1;32m\]'
  c_git_dirty='\[\e[0;31m\]'
else
  c_reset=
  c_user=
  c_git_cleancleann_path=
  c_git_clean=
  c_git_dirty=
fi

# Function to assemble the Git parsingart of our prompt.
git_prompt ()
{ 
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    return 0
  fi
  
  git_branch=$(git branch 2>/dev/null | sed -n '/^\*/s/^\* //p')
  
  if git diff --quiet 2>/dev/null >&2; then
    git_color="$c_git_clean"
  else
    git_color="$c_git_dirty"
  fi
  
  echo "[$git_color$git_branch${c_reset}]"
}


# Function to get conda env.
conda_env ()
{ 
    regex='$\(([^)]+)\)'
    [[ $PS1 =~ $regex ]]
    echo "$BASH_REMATCH"
}

# Thy holy prompt.
PROMPT_COMMAND='PS1="$(conda_env)${c_user}\u${c_reset}@${c_user}\h${c_reset}:${c_path}\w${c_reset}$(git_prompt)\$ "'
```


###### [TMUX-SETUP](https://github.com/brookisme/tmux-setup)

This setup:

- changes the control key from `C-b` to `C-a`
- uses `|` and `-` to split screens
- installs a print package for logging
- a couple other things

```
pushd ~/
rm -rf .tmux*
git clone https://github.com/brookisme/tmux-setup.git
mv tmux-setup/tmux.conf .tmux.conf
rm -rf tmux-setup/
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
popd
```

###### CHECK TENSORFLOW SETUP

```bash
# check TF install
python -c "import tensorflow as tf;print(tf.Session().run(tf.constant('Hi TF')))"
```

###### PY2 CHECKS
```
sa py2
python -c "print 'i am python 2'"
python -c "import keras; print(keras.__version__,'< 2.0')"
python -c "import tensorflow as tf;print(tf.Session().run(tf.constant('Hi TF')))"
```

###### GDAL
```bash
...
```

###### SUBLIME
*NOTE: If you don't reserve a static-ip you are going to have to update the ip-address each time.  With new ip's first log in through gcloud cli to accept private key.*

```json
// example sftp-config.json
// pro-tip: 
//    if you are using on multiple instances put the name 
//    of the instance in a comment and use the sublremote cmd
{
    "type": "sftp",
    "sync_down_on_open": false,
    "upload_on_save":true,
    "host": "<INSTANCE-IP-ADDRESS>",
    "remote_path": "<PATH-TO-SYNCED-REMOTE-DIR>",
    "user": "brook",
    "port":22,
    "ignore_regexes":[
        "/data/",
        "/.kaggle-cli/",
        "\\.sublime-(project|workspace)", 
        "sftp-config(-alt\\d?)?\\.json", 
        "sftp-settings\\.json", "/venv/", 
        "\\.svn", 
        "\\.hg", 
        "\\.git/", 
        "\\.bzr", 
        "_darcs", 
        "CVS", 
        "\\.DS_Store", 
        "Thumbs\\.db", 
        "desktop\\.ini"],
    "connect_timeout": 30,
    "ssh_key_file": "~/.ssh/google_compute_engine"
}
```

I often use multiple machines. A cpu for dev and gpu for training.  In that case i'll create multiple configs, for instance
```
cpu.sftp-config.json
gpu.sftp-config.json
```

And add this cmd to my bash profile

```bash
function sublremote {
    if [[ "$1" = "off"  ]]
    then
        echo "SUBL-REMOTE: OFF"
        if [[ -f sftp-config.json  ]]
        then
           mv sftp-config.json sftp-config.json.bak
        fi
        elif [[  -f $1.sftp-config.json ]]
    then
        if [[ -f sftp-config.json  ]]
        then
           mv sftp-config.json sftp-config.json.bak
        fi
        echo "SUBL-REMOTE: CONNECT < $1 >"
        cp $1.sftp-config.json sftp-config.json
        else
        echo "SUBL-REMOTE: ERROR < config <sftp-config.json.$1> does not exist >"
        fi
}
```

I can now switch syncing and turn off syncing like so...

```bash
$ sublremote cpu
$ sublremote gpu
$ sublremote off
```

---------
&nbsp;
## THE SETUP: ALIASES, DIRECTORIES, PROMPTS 

In addition to setting up CUDNN and installing packages the script added a handful of commands, alaises and other things which I'll mention here.

##### DATA/WEIGHTS

There are directories in the root directory DATA and WEIGHTS which in which I claim all data and weights should go.

- its not in a project directory because you might want to use the same set of data/weights in more than one project, or have different version of projects and you certainly don't want to be copying or moving data around
- its in root, instead of user root, in case other users are also using this instance and logging into a different user root but want access to the same data and weights
- its easy to access
    + I've set up bash alaises `cddata` and `cdweights` so its easy to get there from the command line
    + I've exported the environment vars `DATA` and `WEIGHTS` so that python scripts can access it `os.environ.get('DATA')`.

##### ALAISES/ENV

- `jnb` launches a python notebook
- the python-2 environment is called py2 (`source activate py2`)
- `source activate` is aliased by `sa`
- `source deactivate` is aliased by `sd`
- `kerastf`,`kerasth` switch the keras backend to tensorflow,theano respectively

```bash
# example: go to py2
$ sa py2
$ kerasth

# return to default py3
$ sd
$ kerastf
```

### LOCAL GCLOUD ALAISES

I like to add the following to my .bash(rc)(\_profile). 

Note: `ggo` doesn't always work. The pause is in there because sometimes I get a 255 error, and I _think_ this is because the server isn't ready even though `gstart` has completed. Still playing with this.

```bash
#
# GCLOUD
#
alias gconfig='gcloud config configurations activate'
alias gssh='gcloud compute ssh'
alias gstart='gcloud compute instances start'
alias gstop='gcloud compute instances stop'
ggo(){ echo 'gcloud start: '$1; gstart $1; echo '...pausing for server'; sleep 15; echo 'gcloud ssh: '$1;  gssh $1 ; }
```

 