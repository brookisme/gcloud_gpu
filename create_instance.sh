#!/bin/bash
TEST_RUN=FALSE
NAME=$1
COUNT=$2
IMAGE_FAMILY=ubuntu-1604-lts
# ACCELERATOR=nvidia-tesla-p100
ACCELERATOR=nvidia-tesla-k80


if [ -z $4 ]
then
    STORAGE=${3:-200}
    SNAPSHOT='--'
    SNAPSHOT_DISK_NAME=''
    BOOT_DISK_SIZE='--boot-disk-size '$STORAGE'GB'
else
    STORAGE='--'
    SNAPSHOT=$4
    SNAPSHOT_DISK_NAME='--disk name='$SNAPSHOT',boot=yes'
    BOOT_DISK_SIZE=''
fi

echo ''
echo ''
if [ $COUNT -ne 0 ]
then
    echo 'CREATE GPU: '$NAME' ( '$COUNT' | '$STORAGE' | '$SNAPSHOT' ) '
    cmd="gcloud beta compute instances create ${NAME}
        ${SNAPSHOT_DISK_NAME}
        ${BOOT_DISK_SIZE}
        --machine-type n1-standard-8
        --accelerator type=${ACCELERATOR},count=${COUNT}
        --image-family ${IMAGE_FAMILY} --image-project ubuntu-os-cloud
        --maintenance-policy TERMINATE --restart-on-failure"
else
    echo 'CREATE CPU: '$1' ( '$3' | '$SNAPSHOT' )'
    cmd="gcloud compute instances create ${NAME}
        ${SNAPSHOT_DISK_NAME}
        ${BOOT_DISK_SIZE}
        --machine-type n1-standard-8
        --image-family ${IMAGE_FAMILY} --image-project ubuntu-os-cloud
        --maintenance-policy TERMINATE --restart-on-failure"
fi
if [ "$TEST_RUN" = "TRUE" ]
then
    echo 'create test...'
    echo ${cmd}
else
    ${cmd}
fi
echo ''
echo ''