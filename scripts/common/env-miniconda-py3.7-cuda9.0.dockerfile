# ==================================================================
# module list
# ------------------------------------------------------------------
# python3.7    (miniconda)
# ==================================================================
FROM nvidia/cuda:9.0-devel
RUN APT_INSTALL="apt install -y --no-install-recommends" && \
    rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list && \
    sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' \
        /etc/apt/sources.list && \
    apt update && \

# ==================================================================
# apt tools
# ------------------------------------------------------------------
    DEBIAN_FRONTEND=noninteractive $APT_INSTALL \
        build-essential \
        ca-certificates \
        cmake \
        zip \
        unzip \
        vim \ 
        nano \
        wget \
        curl \
        git \
        aria2 \
        apt-transport-https \
        openssh-client \
        openssh-server \
        libopencv-dev \
        libsnappy-dev \
        tzdata \
        iputils-ping \
        net-tools 

# ==================================================================
# miniconda python3.7
# ------------------------------------------------------------------
RUN curl -so ~/anaconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    chmod +x ~/anaconda.sh && \
    ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh

ENV PATH /opt/conda/bin:$PATH

RUN conda install -y python=3.7 && \
    conda update --all

RUN conda install -y numpy \
                     pandas \
                     jupyterlab \
                     py-opencv \
                     scikit-learn

# change pip source
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple pip -U && \
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple 

# ==================================================================
# mxnet1.3.1
# ------------------------------------------------------------------
RUN pip install gluonbook==0.8.10 \
                gluoncv==0.3.0 \
                opencv-python 
