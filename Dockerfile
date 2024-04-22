FROM nvidia/cuda:11.8.0-devel-ubuntu22.04
ARG RELEASE
ARG LAUNCHPAD_BUILD_ARCH
LABEL org.opencontainers.image.ref.name=ubuntu
LABEL org.opencontainers.image.version=22.04

# Configure environment variables
ARG DEBIAN_FRONTEND=noninteractive
ARG CUDA_ARCHITECTURES=86

# Instale o Conda
RUN apt-get update && \
    apt-get install -y wget bzip2 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh && \
    /bin/bash miniconda.sh -b -p /opt/conda

# Defina a variável de ambiente CUDA_HOME
ENV CUDA_HOME=/usr/local/cuda
# Adicione o CUDA ao PATH
ENV PATH=$CUDA_HOME/bin:$PATH
# Adiciona CUDA library path para LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
# Adicione Conda ao PATH
ENV PATH="/opt/conda/bin:${PATH}"

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc g++

RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc-10 g++-10 && \
    export CC=/usr/bin/gcc-10 && \
    export CXX=/usr/bin/g++-10 && \
    export CUDAHOSTCXX=/usr/bin/g++-10

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    cmake \
    ninja-build \
    build-essential \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libeigen3-dev \
    libflann-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgtest-dev \
    libsqlite3-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libceres-dev

RUN git clone https://github.com/colmap/colmap.git && \
    cd colmap && \
    mkdir build && \
    cd build && \
    cmake .. -GNinja -DCUDA_ENABLED=ON -DCMAKE_CUDA_ARCHITECTURES=${CUDA_ARCHITECTURES} && \
    ninja && \
    ninja install && \
    cd ../.. && \
    rm -rf colmap
    
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg

RUN git clone https://github.com/iuriapereira/floater-free-gaussian-splatting.git --recursive /FFGS

WORKDIR /FFGS

RUN conda create -n abs-gaussian-env python=3.8

# Ative o ambiente Conda e instale as dependências adicionais
SHELL ["/bin/bash", "-c"]
#RUN conda create --name sugar
RUN conda init bash
RUN echo "conda activate abs-gaussian-env" >> ~/.bashrc
RUN source ~/.bashrc

ENV PATH /opt/conda/envs/ffgs/bin:$PATH
SHELL ["/bin/bash", "-c"]

RUN echo "pip install torch==1.13.1+cu116 torchvision==0.14.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116" >> ~/.bashrc && \
    echo "pip install -r requirements.txt" >> ~/.bashrc
RUN source ~/.bashrc

RUN echo "cd submodules/diff-gaussian-rasterization/" >> ~/.bashrc && \
    echo "pip install -e ." >> ~/.bashrc && \
    echo "cd ../simple-knn/" >> ~/.bashrc && \
    echo "pip install -e ." >> ~/.bashrc && \
    echo "cd ../../../" >> ~/.bashrc
RUN source ~/.bashrc

RUN pip install gdown
RUN pip install plyfile
RUN pip install tqdm

EXPOSE 80
