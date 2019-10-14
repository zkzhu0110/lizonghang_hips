#!/bin/bash

# stop all MXNET process
STOP_MXNET_COMMAND="ps -ef | grep \"python.*\" | \
                    cut -c 10-15 | xargs kill"

containers_ip=\
(
    172.17.34.2 172.17.34.3 172.17.34.4 172.17.34.5
    172.17.29.2 172.17.29.3 172.17.29.4 172.17.29.5
    172.17.33.2 172.17.33.3 172.17.33.4 172.17.33.5
)

for ip in ${containers_ip[*]}; do
    ssh root@$ip $STOP_MXNET_COMMAND
done
