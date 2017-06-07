#!/bin/bash

#
# DOWNLOAD VERSIONS
#
CUDA_VERSION=cuda-repo-ubuntu1604_8.0.61-1_amd64.deb
ANACONDA_VERSION=Anaconda3-4.4.0-Linux-x86_64.sh
TENSORFLOW_VERSION=tensorflow_gpu-1.0.0-cp36-cp36m-linux_x86_64.whl
TENSORFLOW_VERSION_PY2=tensorflow_gpu-1.0.1-cp27-none-linux_x86_64.whl


#
# DOWNLOAD BASE
#
CUDA_DOWNLOAD_BASE=http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64
ANACONDA_DOWNLOAD_BASE=https://repo.continuum.io/archive
TENSORFLOW_BASE=https://storage.googleapis.com/tensorflow/linux/gpu



cd ~/

### CUDA
echo ''
echo ''
echo "Checking for CUDA and installing."
if ! dpkg-query -W cuda; then
  curl -O $CUDA_DOWNLOAD_BASE'/'$CUDA_VERSION
  sudo dpkg -i ./$CUDA_VERSION
  sudo apt-get update
  sudo apt-get install -y cuda 
fi


### install pip
sudo apt-get install -y python-pip

### Anaconda
echo ''
echo ''
echo "Anaconda Install:"
echo "    Anaconda install is interactive please enter/yes to all"
echo "    **The default for append .bashrc is [no] type yes!!**"
echo ''
wget $ANACONDA_DOWNLOAD_BASE/$ANACONDA_VERSION
bash $ANACONDA_VERSION

### bashrc
mv ~/.bashrc ~/.bashrc.bak
echo "
#
# ADDITIONAL BASH
#
alias vibash='vi ~/.bashrc'
alias sourcebash='. ~/.bashrc'
lsports(){ sudo lsof -n -i | grep $1 | grep LISTEN ; }

#
# GIT
#
alias gpo='git push origin'
alias gs='git status'
alias gc='git commit -am'

# Configure colors, if available. (http://vvv.tobiassjosten.net/bash/dynamic-prompt-with-git-and-ansi-colors/)
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

# Thy holy prompt.
PROMPT_COMMAND='PS1="${c_user}\u${c_reset}@${c_user}\h${c_reset}:${c_path}\w${c_reset}$(git_prompt)\$ "'


#
# ML DIRS
#
export DATA=/data
export WEIGHTS=/weights
cddata(){ cd ${DATA}/$1; }
cdweights(){ cd ${WEIGHTS}/$1; }

#
# CUDA
#
export CUDA_HOME=/usr/local/cuda-8.0 
export LD_LIBRARY_PATH=${CUDA_HOME}/lib64
PATH=${CUDA_HOME}/bin:${PATH} 
export PATH

#
# HELPERS
#

# gcloud
alias gconfig='gcloud config configurations activate' 
alias gssh='gcloud compute ssh' 

# files
alias sampletree='mkdir -p sample/{train,test,valid}'
lsn(){ matchdir=`pwd`/$2; find $matchdir -type f | grep -v sample | shuf -n $1 | awk -F`pwd` '{print "."$NF}' ; }
cpn(){ matchdir=`pwd`/$2; find $matchdir -type f | grep -v sample | shuf -n $1 | awk -F`pwd` '{print "."$NF" sample"$NF}' | xargs -t -n2 cp ; }
mvn(){ matchdir=`pwd`/$2; todir=`pwd`/$3; find $matchdir -type f | grep -v sample | shuf -n $1 | awk -F`pwd` -v todir="$todir" '{print $0" "todir}' | xargs -t -n2 mv ; }
cpnh(){ matchdir=`pwd`/$2; find $matchdir -type f | grep -v sample | head -n $1 | awk -F`pwd` '{print "."$NF" sample"$NF}' | xargs -t -n2 cp ; }
mvnh(){ matchdir=`pwd`/$2; todir=`pwd`/$3; find $matchdir -type f | grep -v sample | head -n $1 | awk -F`pwd` -v todir="$todir" '{print $0" "todir}' | xargs -t -n2 mv ; }
cpnt(){ matchdir=`pwd`/$2; find $matchdir -type f | grep -v sample | tail -n $1 | awk -F`pwd` '{print "."$NF" sample"$NF}' | xargs -t -n2 cp ; }
mvnt(){ matchdir=`pwd`/$2; todir=`pwd`/$3; find $matchdir -type f | grep -v sample | tail -n $1 | awk -F`pwd` -v todir="$todir" '{print $0" "todir}' | xargs -t -n2 mv ; }


# anaconda
alias sd='source deactivate'
alias sa='source activate'
alias jnb='jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser &'

# keras
kerastf() {
    rm -rf ~/.keras/keras.json
    cp ~/.keras/keras.json.tensor ~/.keras/keras.json
    cat ~/.keras/keras.json
}
kerasth() {
    rm -rf ~/.keras/keras.json
    cp ~/.keras/keras.json.theano ~/.keras/keras.json
    cat ~/.keras/keras.json
}
kerastfth() {
    rm -rf ~/.keras/keras.json
    cp ~/.keras/keras.json.tensorth ~/.keras/keras.json
    cat ~/.keras/keras.json
}


#
# INITIAL BASH
#


" > ~/.bashrc  
cat ~/.bashrc.bak >> ~/.bashrc 
source ~/.bashrc

### DIRECTORIES
sudo mkdir $DATA
sudo mkdir $WEIGHTS
sudo chmod 755 $DATA
sudo chmod 755 $WEIGHTS

### ML
conda install -y pytorch torchvision cuda80 -c soumith

### THEANO
conda install -y theano
echo '
[cuda] 
root = /usr/local/cuda-8.0
'>>~/.theanorc

### Tensorflow
echo ''
echo ''
echo "TensorFlow Install:"
TF=$TENSORFLOW_BASE/$TENSORFLOW_VERSION
pip install --ignore-installed --upgrade $TF

### KERAS
pip install keras
# keras tensorflow setup
echo '{
    "image_dim_ordering": "tf",
    "epsilon": 1e-07,
    "floatx": "float32",
    "backend": "tensorflow"
}' > ~/.keras/keras.json.tensor
# keras theano setup
echo '{
    "image_dim_ordering": "th",
    "epsilon": 1e-07,
    "floatx": "float32",
    "backend": "theano"
}' > ~/.keras/keras.json.theano
# keras tensorflow-th setup
echo '{
    "image_dim_ordering": "th",
    "epsilon": 1e-07,
    "floatx": "float32",
    "backend": "tensorflow"
}' > ~/.keras/keras.json.tensorth


### TOOLS
echo ""
echo ""
echo "TOOLS..."
sudo apt-get install -y unzip
sudo apt-get install -y tree
pip install kaggle-cli
conda install -y libgcc
pip install bcolz
pip install gitnb

### REINSTALL NUMPY <sk-image error>
# - Intel MKL FATAL ERROR: Cannot load libmkl_avx2.so or libmkl_def.so.
# - https://github.com/ContinuumIO/anaconda-issues/issues/720
conda install  -fy  numpy

#
# PYTHON-2
# 
echo ""
echo ""
echo "PYTHON-2 SETUP"
conda create -y -n py2 python=2 anaconda
source activate py2
# tensorflow
TF=$TENSORFLOW_BASE/$TENSORFLOW_VERSION_PY2
pip install --ignore-installed --upgrade $TF
# keras 1 ( to be consistent with fastai-part-1 notebooks )
pip install 'keras<2' 
# other
conda install -y libgcc
pip install bcolz
# deactivate
source deactivate



