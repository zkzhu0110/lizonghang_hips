# HiPS

HiPS is a hierarchical parameter server framework implemented based on MXNET, whose goal is to integrate data knowledge that owned by multiple independent parties in a privacy-preservating way (i.e. no need to transfer raw data), by training a shared deep learning model collaboratively in a decentralized and distributed manner.

Unlike other distributed deep learning software framworks (e.g. MXNET, TensorFlow, PyTorch) and the emerging Federated Learning technologies which are based on single-layer parameter server architecture, HiPS applies double-layer architecture to reduce communication cost between parties. 
HiPS allows parties to train the deep learning model on their own data and clusters in a distributed mannar locally, and parties only need to upload the locally aggregated model gradients (or model updates) to the central party to perform global aggregation, model updating and model synchronization.


An overview of HiPS is shown below.
<div align="center"><img src="images/HiPS-overview.png" width="600px" /></div>

## Prerequisites
At least 3 host machines with network connected are required, and nvidia-docker is installed on these hosts: 

* nvidia-docker == 18.06.3-ce

The hosts are ready if they can successfully run: 
```
$ nvidia-docker run -it --rm nvidia/cuda:9.0-devel nvidia-smi
``` 
To achieve that, cuda and nvidia-driver with compatible version should be correctly installed.

## How to run the demo
We provide a FedAvg demo in the folder `HiPS-app/`, which is implemented based on HiPS. To run this demo, we should build an image and run several containers. Assume that we have 3 host machines:

* A: IP 10.1.1.34
* B: IP 10.1.1.29
* C: IP 10.1.1.33

### Build Image

Before building the docker images, create a data folder at `hips-docker/data` and move the data file into it. Take the CIFAR10 image classification dataset as example, download CIFAR10 and move it to the specified path:
```
$ cd hips-docker
$ mkdir data
$ mv /path/to/cifar10 data/
$ ls data/cifar10
batches.meta.txt  data_batch_2.bin  data_batch_4.bin  test_batch.bin
data_batch_1.bin  data_batch_3.bin  data_batch_5.bin
```

Then you can build the basic image `miniconda-py3.7-cuda9.0` using dockerfile `scripts/common/env-miniconda-py3.7-cuda9.0.dockerfile`, and build the developing image `hips` using dockerfile `scripts/common/app-hips-dev.dockerfile`:
```
$ cd hips-docker
$ sudo docker build -f scripts/common/env-miniconda-py3.7-cuda9.0.dockerfile -t miniconda-py3.7-cuda9.0 .
$ vim scripts/common/app-hips-dev.dockerfile
(vim) delete FROM lizonghango00o1/miniconda-py3.7-cuda9.0
(vim) add FROM miniconda-py3.7-cuda9.0
$ sudo docker build -f scripts/common/app-hips-dev.dockerfile -t hips .
```
Or you can build the developing image `hips` directly by:
```
$ cd hips-docker
$ sudo docker build -f scripts/common/app-hips-dev.dockerfile -t hips .
```

### Configure Network

Containers are separated into three networks and they should be able to communicate with others.

* A: bridge docker0, 172.17.34.0/24
* B: bridge docker0, 172.17.29.0/24
* C: bridge docker0, 172.17.33.0/24

To separate the network, add the following configuration to `/etc/docker/daemon.json` on host A, B and C and restart docker:
```
// on host A (IP 10.1.1.34), set 172.17.29.1/24 on host B
// and set 172.17.33.1/24 on host C.
$ sudo vim /etc/docker/daemon.json
(vim) {
(vim)   "bip": "172.17.34.1/24"  
(vim) }
$ sudo service docker restart
$ sudo service docker status
```

Then configure the route table on host A, B and C to forward IP packets:
```
// on host A (IP 10.1.1.34)
$ sudo route add -net 172.17.29.0 netmask 255.255.255.0 gw 10.1.1.29
$ sudo route add -net 172.17.33.0 netmask 255.255.255.0 gw 10.1.1.33
// on host B (IP 10.1.1.29)
$ sudo route add -net 172.17.33.0 netmask 255.255.255.0 gw 10.1.1.33
$ sudo route add -net 172.17.34.0 netmask 255.255.255.0 gw 10.1.1.34
// on host C (IP 10.1.1.33)
$ sudo route add -net 172.17.29.0 netmask 255.255.255.0 gw 10.1.1.29
$ sudo route add -net 172.17.34.0 netmask 255.255.255.0 gw 10.1.1.34
```

Finally, configure the iptables on host A, B and C to support SNAT:
```
$ sudo iptables -P INPUT ACCEPT
$ sudo iptables -P FORWARD ACCEPT
$ sudo iptables -t nat -F POSTROUTING
// on host A (IP 10.1.1.34)
$ sudo iptables -t nat -A POSTROUTING -s 172.17.34.0/24 ! -d 172.17.0.0/16 -j MASQUERADE
// on host B (IP 10.1.1.29)
$ sudo iptables -t nat -A POSTROUTING -s 172.17.29.0/24 ! -d 172.17.0.0/16 -j MASQUERADE
// on host C (IP 10.1.1.33)
$ sudo iptables -t nat -A POSTROUTING -s 172.17.33.0/24 ! -d 172.17.0.0/16 -j MASQUERADE
```

### Run Containers

The scripts for running containers are available at `scripts/host1`, `scripts/host2`, `scripts/host3` respectively. The scripts will automatically run a container, set environment variables, map necessary ports outside, start ssh and configure public keys (read from `ssh_keys`), and compile mxnet automatically. It may take about 30 minutes to complete.

> NOTE: Always start scheduler and global scheduler first to ensure their IP addresses are 172.17.XX.2 and 172.17.XX.3 respectively, otherwise the process would fail to bind the ports. 

> NOTE: Make sure that ports 9090-9095 is not used by other processes, otherwise the process would also fail to bind the ports.

#### Start Containers on Host A:

* **Scheduler**: There is only one scheduler in a party, whose role is to set up the cluster. This includes waiting for messages that each node has come up and which port the node is listening on. The scheduler then lets all processes  know about every other node in the cluster inside a party, so that they can communicate with each other.
```
$ ./scripts/host1/start-scheduler-container.sh
```

* **Global Scheduler**: Similar to the scheduler but its role is to set up communication between multiple parties.
```
$ ./scripts/host1/start-global-scheduler-container.sh
```

* **Global Server**: Similar to server but its role is to communicate with servers of multiple parties and aggregate model gradients from them.
```
$ ./scripts/host1/start-global-server-container.sh
```

* **Master Worker**: Master Worker is a special worker, it only initialize the model on the global server but will not participate in model training. But you can set `ENABLE_CENTRAL_WORKER=1` to enable workers in the central party to participate in model training (include master work). If `ENABLE_CENTRAL_WORKER` is set to 0, all push requests from workers in the central party would be discarded, so make sure you did not perform any push/pull operations on these workers because it is just a waste of communication resources.
```
$ ./scripts/host1/start-master-worker.sh
```

#### Start Containers on Other Hosts:

> NOTE: Host B use `scripts/host2` and host C use `scripts/host3`.

* **Scheduler**:
```
$ ./scripts/host2/start-scheduler.sh
```

* **Server**: Servers communicate with their workers and aggregate model gradients from them, then servers push the aggregated model gradients to the global server and wait for the global server's data response, workers will pull new model parameters or aggregated model gradients from servers.
```
$ ./scripts/host2/start-server.sh
```

* **Worker**: A worker node actually performs training on a batch of training samples. Before processing each batch, the workers pull weights from servers. The workers also send gradients to the servers after each batch.
```
$ ./scripts/host2/start-worker0.sh
$ ./scripts/host2/start-worker1.sh
```

### Run the FedAvg application

The application codes are placed at `HiPS-app/` and the quick start scripts are placed at `scripts/common`, including `start-all-process.sh`, `stop-all-process.h`, `sync-file.sh` and `destroy-all-container.sh`. Make sure the IP addresses and paths in these scripts are correct, otherwise, your cluster may be in a mess.
The application is to train an AlexNet model using FedAvg algorithm on CIFAR10, where the cluster contains 4 workers in total (2 workers in host A ad 2 workers in host B).

#### Quick Start

Use the script `start-all-process.sh` to start all processes in each container. Make sure that this script is synchronized across host A, B and C.
```
$ ./scripts/common/start-all-process.sh
```
It may take about 5 minutes to complete the first round. If everything is ok, use `docker exec hips-worker0 cat logs/net.meta` or `docker exec hips-worker1 cat logs/net.meta` to see the latest states. Logs will be writed at `/root/HiPS-app/logs/gpu0` and model will be saved at `/root/HiPS-app/logs/net.params` for every `EVAL_DURATION` rounds.
```
$ sudo docker exec hips-worker1 cat logs/net.meta
{"global_iters": 94, "test_acc": 0.6998407643312102, "learning_rate": 0.001, "ba
tch_size": 64, "begin_time": 1568790726.4896832}
```

If something is wrong, use `scripts/common/stop-all-process.sh` to stop all processes and start each process manually.
```
$ ./scripts/common/stop-all-process.sh
```

#### Start the Cluster Manually

Open 12 terminal windows, 4 windows for host A, 4 windows for host B and 4 windows for host C. Use `docker exec -ti $CONTAINER_NAME bash` to enter all the containers, and run the following commands in different windows:

* Host A

Run the following command in 3 windows to start scheduler, global scheduler and global server respectively:
```
$ python main.py
```

Run the following command in 1 windows to start master worker:
```
$ python main.py -c 1
```

* Host B and Host C

Run the following command in 2 windows to start scheduler and server:
```
$ python main.py
```

Run the following command in the rest 2 windows to start worker0 and worker1 respectively:
```
// on host B
$ python main.py -m sync -n alexnet -l 0.001 -b 64 -le 5 -e 1 -ds 0
$ python main.py -m sync -n alexnet -l 0.001 -b 64 -le 5 -e 1 -ds 1
// on host C
$ python main.py -m sync -n alexnet -l 0.001 -b 64 -le 5 -e 1 -ds 2
$ python main.py -m sync -n alexnet -l 0.001 -b 64 -le 5 -e 1 -ds 3
```

If anything goes wrong, you will see the error information.

#### Synchronize Files Across Hosts

Use `scripts/common/sync-file.sh` on host A to synchronize files to host B, host C and all the containers. If you modify `HiPS-app/trainer/sync_trainer.py`, you can add its path to `files` in `sync-file.sh` and run the script:
```
$ vim ./scripts/common/sync-file.sh
(vim) ...
(vim) files=\
(vim) (
(vim)   HiPS-app/trainer/sync_trainer.py
(vim) )
(vim) ...
$ ./sync-file.sh
```

## Updates

Date | Author | Content | Description | Note
:-: | :-: | :-: | :-- | :--
2019/09/21 | Zonghang LI | Load Balance | Support key management in 2L-PS. |
2019/09/25 | Zonghang LI | Load Balance | Support uniform tensor slice in 2L-PS. | 
2019/09/25 | Zonghang LI | Traffic Model | Change push/broadcast mode to push/pull mode in 2L-PS. |
2019/09/25 | Zonghang LI | Optimizer | Support asynchronous FedAvg & ASGD && DC-ASGD. |
2019/09/27 | Zonghang LI | Gradient Compression | Support 2bits gradient compression. Set `USE_2BIT_COMPRESSION=1` in config.py to enable gradient compression. | Call `time.sleep` manually to make sure that `gradient_compression_` on servers has been configured before calling pull, otherwise the processes would be stucked due to mismatch of `gradient_compression_` between servers and global servers. 

> **NOTE: Any problem is welcome, contact Zonghang LI for more details.**
> * QQ: 870644199
> * WeChat: lizonghango00o1
