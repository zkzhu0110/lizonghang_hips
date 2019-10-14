#!/bin/bash

MODE=sync
NET=alexnet
LEARNING_RATE=0.001
BATCH_SIZE=64
NUM_LOCAL_EPOCHS=5
EVAL_DURATION=1

MYIP=$(ifconfig em1 | grep 'inet' | grep -v 'inet6' | cut -c 21-31)

if [ "$MYIP" == "10.2.11.170" ]; then
    sudo docker exec -di hips-scheduler bash -c "python main.py"
    sudo docker exec -di hips-global-scheduler bash -c "python main.py"
    sudo docker exec -di hips-global-server0 bash -c "python main.py"
    sudo docker exec -di hips-master-worker bash -c "python main.py -c 1"
fi

if [ "$MYIP" == "10.2.11.171" ]; then
    sudo docker exec -di hips-scheduler bash -c "python main.py"
    sudo docker exec -di hips-server0 bash -c "python main.py"
    sudo docker exec -di hips-worker0 bash -c "python main.py \
            -m $MODE -n $NET -l $LEARNING_RATE -b $BATCH_SIZE -le $NUM_LOCAL_EPOCHS -e $EVAL_DURATION -ds 0"
    sudo docker exec -di hips-worker1 bash -c "python main.py \
            -m $MODE -n $NET -l $LEARNING_RATE -b $BATCH_SIZE -le $NUM_LOCAL_EPOCHS -e $EVAL_DURATION -ds 1"
fi

if [ "$MYIP" == "10.2.11.172" ]; then
    sudo docker exec -di hips-scheduler bash -c "python main.py"
    sudo docker exec -di hips-server0 bash -c "python main.py"
    sudo docker exec -di hips-worker0 bash -c "python main.py \
            -m $MODE -n $NET -l $LEARNING_RATE -b $BATCH_SIZE -le $NUM_LOCAL_EPOCHS -e $EVAL_DURATION -ds 2"
    sudo docker exec -di hips-worker1 bash -c "python main.py \
            -m $MODE -n $NET -l $LEARNING_RATE -b $BATCH_SIZE -le $NUM_LOCAL_EPOCHS -e $EVAL_DURATION -ds 3"
fi

HOST_NAME=lizh
other_hosts=\
(
    10.2.11.171
    10.2.11.172
)

if [ "$MYIP" == "10.2.11.170" ]; then
    for ip in ${other_hosts[*]}; do
        ssh $HOST_NAME@$ip ~/hips-docker/scripts/common/start-all-process.sh
    done
fi
