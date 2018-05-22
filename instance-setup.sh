#!/bin/bash


#
# DOWNLOAD VERSIONS
#
ANACONDA_VERSION=Anaconda3-5.1.0-Linux-x86_64.sh
ANACONDA_DOWNLOAD_BASE=https://repo.continuum.io/archive

cd ~/

#
# TENSORFLOW DOWNLOAD
#
if [ "$1" = "cpu" ]; then
    echo "CPU SETUP:"
    TENSORFLOW_BASE=https://storage.googleapis.com/tensorflow/linux/cpu
    TENSORFLOW_VERSION=tensorflow-1.4.0-cp36-cp36m-linux_x86_64.whl
    TENSORFLOW_VERSION_PY2=tensorflow-1.4.0-cp27-none-linux_x86_64.whl
else
    echo "GPU SETUP:"
    CUDA_DOWNLOAD_BASE=http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64
    CUDA_VERSION=cuda-repo-ubuntu1604_9.1.85-1_amd64.deb
    TENSORFLOW_BASE=https://storage.googleapis.com/tensorflow/linux/gpu
    TENSORFLOW_VERSION=tensorflow_gpu-1.4.0-cp36-cp36m-linux_x86_64.whl
    TENSORFLOW_VERSION_PY2=tensorflow_gpu-1.4.0-cp27-none-linux_x86_64.whl
    ### CUDA
    echo ''
    echo ''
    echo "Checking for CUDA and installing."
    # QUESTION: does the .pub file always have the same name?
    sudo apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub
    if ! dpkg-query -W cuda; then
      curl -O $CUDA_DOWNLOAD_BASE'/'$CUDA_VERSION
      sudo dpkg -i ./$CUDA_VERSION
      sudo apt-get update
      sudo apt-get install -y cuda 
    fi
fi


### install pip
sudo apt-get update
sudo apt-get install -y python-pip
pip install --upgrade pip

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
lsports(){ sudo lsof -n -i | grep \$1 | grep LISTEN ; }

#
# GIT
#
alias gpo='git push origin'
alias gs='git status'
alias gc='git commit'

#
# ML DIRS
#
export DATA=/data
export WEIGHTS=/weights
cddata(){ cd \${DATA}/\$1; }
cdweights(){ cd \${WEIGHTS}/\$1; }

#
# CUDA
#
export CUDA_HOME=/usr/local/cuda-9.1 
export LD_LIBRARY_PATH=\${CUDA_HOME}/lib64
PATH=\${CUDA_HOME}/bin:\${PATH} 
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
alias jnb='jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser'

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
sudo chmod 777 $DATA
sudo chmod 777 $WEIGHTS


### GDAL
sudo apt-get install libgdal-dev gdal-bin 
conda install -y gdal


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
if [ "$2" != "skip-tf" ]; then
    echo "TensorFlow Install:"
    TF=$TENSORFLOW_BASE/$TENSORFLOW_VERSION
    pip install --ignore-installed --upgrade $TF
else
    echo "Tensorflow not installed: Install from source:"
    echo "https://www.tensorflow.org/install/install_sources"
fi

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
sudo apt-get install -y p7zip-full
pip install kaggle-cli
conda install -y libgcc
pip install bcolz
pip install gitnb


### GEO-TOOLS

if [ "$3" != "skip-geo" ]; then
    echo "Installing GEO-TOOLS:"
    conda install -y shapely
    conda install -y cartopy
    conda install -y fiona
    conda install -y rasterio
    conda install -y -c conda-forge geopandas
else
    echo "GEO-TOOLS not installed"
fi

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
### Tensorflow
echo ''
echo ''
if [ "$2" != "skip-tf" ]; then
    echo "TensorFlow Install:"
    TF=$TENSORFLOW_BASE/$TENSORFLOW_VERSION_PY2
    pip install --ignore-installed --upgrade $TF
else
    echo "Tensorflow not installed: Install from source:"
    echo "https://www.tensorflow.org/install/install_sources"
fi

# use keras 1 if you want to be consistent with fastai-part-1 notebooks
# pip install 'keras<2' 
pip install keras

# other
conda install -y libgcc
pip install bcolz
# deactivate
source deactivate



