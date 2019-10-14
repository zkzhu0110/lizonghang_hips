#!/bin/bash

# require sudo with no password, set USER ALL=(ALL:ALL) NOPASSWD:ALL
# in file /etc/sudoers

# hosts ip except myself
other_hosts_ip=\
(
    10.2.11.171
    10.2.11.172
)

# destroy self containers
my_containers_name=\
(
    hips-global-scheduler
    hips-scheduler
    hips-global-server0
    hips-master-worker
)

# destroy containers on other hosts
other_containers_name=\
(
    hips-scheduler
    hips-server0
    hips-worker0
    hips-worker1
)

HOST_NAME=lizh

for container in ${my_containers_name[*]}; do
    sudo docker stop $container && sudo docker rm $container
done

for host in ${other_hosts_ip[*]}; do
    for container in ${other_containers_name[*]}; do
        ssh $HOST_NAME@$host "sudo docker stop $container && sudo docker rm $container"
    done
done
