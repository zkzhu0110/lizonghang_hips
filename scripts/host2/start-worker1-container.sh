#!/bin/bash

# configure the network on host machine.
# assume the host ip is 10.1.1.34, add we need to
# connect 172.17.33.2 on host machine 10.1.1.33
# and 172.17.29.2 on host machine 10.1.1.29.
#
# following configurations to /etc/docker/daemon.json:
# # sudo vim /etc/docker/daemon.json
# {
#   "bip": "172.17.34.1/24"
# }
# stop all running containers and restart docker:
# # sudo systemctl restart docker
#
# configure the routes to forward ip packets:
# # sudo route add -net 172.17.33.0 netmask 255.255.255.0 gw 10.1.1.33
# # sudo route add -net 172.17.29.0 netmask 255.255.255.0 gw 10.1.1.29
# # sudo route -n
#
# configure the iptables to allow MASQUERADE (special SNAT):
# # sudo iptables -t nat -F POSTROUTING
# # sudo iptables -t nat -A POSTROUTING -s 172.17.34.0/24 ! \
# #               -d 172.17.0.0/16 -j MASQUERADE
# # sudo iptables -P INPUT ACCEPT
# # sudo iptables -P FORWARD ACCEPT
#
# start a container and try to ping containers
# on other host machines.

# container
IMAGE_NAME=hips
CONTAINER_NAME=hips-worker1
HOST_NAME=worker1
CONTAINER_PORT=9095
SSH_PORT=9005
GPU_ID=1

# app
DMLC_ROLE=worker
DMLC_PS_ROOT_URI=172.17.29.2
DMLC_PS_ROOT_PORT=9092
DMLC_NUM_SERVER=1
DMLC_NUM_WORKER=2
DMLC_NUM_ALL_WORKER=6
PS_VERBOSE=1 
DMLC_INTERFACE=eth0

sudo docker run -dit \
                --name $CONTAINER_NAME \
                -h $HOST_NAME \
                --cpus 8 \
                -m 12G \
                --memory-swap -1 \
                --shm-size 2G \
                -e NVIDIA_VISIBLE_DEVICES=$GPU_ID \
                -e DMLC_ROLE=$DMLC_ROLE \
                -e DMLC_PS_ROOT_URI=$DMLC_PS_ROOT_URI \
                -e DMLC_PS_ROOT_PORT=$DMLC_PS_ROOT_PORT \
                -e DMLC_NUM_SERVER=$DMLC_NUM_SERVER \
                -e DMLC_NUM_WORKER=$DMLC_NUM_WORKER \
                -e DMLC_NUM_ALL_WORKER=$DMLC_NUM_ALL_WORKER \
                -e PS_VERBOSE=$PS_VERBOSE \
                -e DMLC_INTERFACE=$DMLC_INTERFACE \
                -e PORT=$CONTAINER_PORT \
                -e LD_LIBRARY_PATH=/root/HiPS/lib:/root/HiPS/deps/lib:/usr/lib \
                -e PYTHONPATH=/root/HiPS/python \
                -e MXNET_CUDNN_AUTOTUNE_DEFAULT=0 \
                -p $CONTAINER_PORT:$CONTAINER_PORT \
                -p $SSH_PORT:22 \
                -v /etc/localtime:/etc/localtime \
                $IMAGE_NAME

# set root password
PASSWORD=199014a
sudo docker exec $CONTAINER_NAME bash -c "\
    echo root:$PASSWORD | chpasswd"

# start ssh and configure public keys
PUBKEY=$(cat ssh_keys)
sudo docker exec $CONTAINER_NAME bash -c "\
    /etc/init.d/ssh start && \
    mkdir /root/.ssh && \
    echo \"$PUBKEY\" > /root/.ssh/authorized_keys"

# make mxnet
sudo docker exec $CONTAINER_NAME bash -c "\
    cd /root/HiPS && \
    make clean_all && \
    make -j8 && \
    cd /root/HiPS-app"
