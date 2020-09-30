# Dockerfile
FROM ubuntu:16.04

# Installs necessary dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
         build-essential \
         cmake \
         git \
         wget \
         curl \
         ca-certificates \
         libjpeg-dev \
         libpng-dev \
         zip \
         unzip && \
     rm -rf /var/lib/apt/lists/*

# Install Miniconda and Python 3.6
ARG PYTHON_VERSION=3.6
ENV CONDA_AUTO_UPDATE_CONDA=false
ENV PATH=/home/user/miniconda/bin:$PATH
RUN curl -o ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
     chmod +x ~/miniconda.sh && \
     ~/miniconda.sh -b -p /opt/conda && \
     rm ~/miniconda.sh && \
     /opt/conda/bin/conda install -y python=$PYTHON_VERSION numpy pyyaml scipy ipython mkl mkl-include ninja cython typing && \
     /opt/conda/bin/conda install -y -c pytorch magma-cuda100 && \
     /opt/conda/bin/conda clean -ya
ENV PATH /opt/conda/bin:$PATH

# CUDA 10.1-specific steps
RUN conda install -y -c pytorch \
    cudatoolkit=10.1 \
    "pytorch=1.4.0=py3.6_cuda10.1.243_cudnn7.6.3_0" \
    "torchvision=0.5.0=py36_cu101" \
 && conda install -y pip \
 && conda clean -ya

# Installs google cloud sdk, this is mostly for using gsutil to export model.
RUN wget -nv \
    https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz && \
    mkdir /root/tools && \
    tar xvzf google-cloud-sdk.tar.gz -C /root/tools && \
    rm google-cloud-sdk.tar.gz && \
    /root/tools/google-cloud-sdk/install.sh --usage-reporting=false \
        --path-update=false --bash-completion=false \
        --disable-installation-options && \
    rm -rf /root/.config/* && \
    ln -s /root/.config /config && \
    # Remove the backup directory that gcloud creates
    rm -rf /root/tools/google-cloud-sdk/.install/.backup

# Path configuration
ENV PATH $PATH:/root/tools/google-cloud-sdk/bin
# Make sure gsutil will use the default service account
RUN echo '[GoogleCompute]\nservice_account = default' > /etc/boto.cfg

RUN pip install cloudml-hypertune \
 dominate>=2.4.0 \
 visdom>=0.1.8.8 \
 packaging \
 GPUtil>=1.4.0 \
 pandas \
 google-cloud-storage

RUN wget https://storage.googleapis.com/nets-datasets/grumpifycat.zip -P ./datasets/ \
 && unzip ./datasets/grumpifycat.zip -d ./datasets/ \
 && rm ./datasets/grumpifycat.zip

COPY . .

EXPOSE 8097
ENTRYPOINT ["python", "train.py", "--dataroot", "./datasets/grumpifycat",  "--name", "grumpycat_CUT", "--CUT_mode", "CUT", "--gpu_ids", "-1", "--display_id", "0"]
#CMD ["/bin/bash"]
