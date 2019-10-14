FROM lizonghango00o1/miniconda-py3.7-cuda9.0

RUN APT_INSTALL="apt install -y --no-install-recommends" && \
    apt update && \
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        libopenblas-dev \
        libatlas-base-dev

COPY . /root/

RUN cd /root/scripts/common && \
    tar -xzvf cudnn-9.0-linux-x64-v7.6.2.24.tgz && \
    cp cuda/include/cudnn.h /usr/local/cuda/include && \
    cp cuda/lib64/libcudnn* /usr/local/cuda/lib64 && \
    chmod a+r /usr/local/cuda/include/cudnn.h /usr/local/cuda/lib64/libcudnn* && \
    rm cudnn-9.0-linux-x64-v7.6.2.24.tgz && \
    rm -r cuda

WORKDIR /root/HiPS-app
