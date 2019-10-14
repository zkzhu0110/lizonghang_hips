#!/bin/bash

HOST_USER=lizh
HOST_WORK_DIR=/home/lizh/hips-docker
CONTAINER_USER=root
CONTAINER_WORK_DIR=/root/

# target hosts 
hosts_ip=\
(
    10.2.11.171
    10.2.11.172
)

# target containers
containers_ip=\
(
    172.17.34.2 172.17.34.3 172.17.34.4 172.17.34.5
    172.17.29.2 172.17.29.3 172.17.29.4 172.17.29.5
    172.17.33.2 172.17.33.3 172.17.33.4 172.17.33.5
)

# files that need to synchronize
files=\
(
    HiPS-app/main.py
#    HiPS-app/config.py
#    HiPS-app/utils.py
    HiPS-app/trainer/sync_trainer.py
#    scripts/common/start-all-process.sh
)

echo "==========================="
echo "Synchronizing code files..."
echo "---------------------------"

# synchronize files to hosts and containers
for ip in ${hosts_ip[*]}; do
    for file in ${files[*]}; do
        scp $HOST_WORK_DIR/$file $HOST_USER@$ip:$HOST_WORK_DIR/$file
    done
done

for ip in ${containers_ip[*]}; do
    for file in ${files[*]}; do
        scp $HOST_WORK_DIR/$file $CONTAINER_USER@$ip:$CONTAINER_WORK_DIR/$file
    done
done

echo "Finished."
echo "==========================="

echo "==========================="
echo "Synchronizing library..."
echo "---------------------------"

libraries=\
(
)

for lib in ${libraries[*]}; do
    for ip in ${containers_ip[*]}; do
        scp -r $lib $CONTAINER_USER@$ip:$CONTAINER_WORK_DIR/HiPS/
    done
done

echo "Finished."
echo "==========================="
