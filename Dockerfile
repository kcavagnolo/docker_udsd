# base image
FROM nvidia/cuda:8.0-cudnn5-devel

# maintainer
MAINTAINER Ken Cavagnolo <ken@kcavagnolo.com>

# set env
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV LD_LIBRARY_PATH /usr/local/cuda/lib64/:$LD_LIBRARY_PATH
COPY jupyter_notebook_config.py /root/.jupyter/
COPY run_jupyter.sh /

# update OS
RUN \
  set -ex && \
  echo 'DPkg::Post-Invoke {"/bin/rm -f /var/cache/apt/archives/*.deb || true";};' | tee /etc/apt/apt.conf.d/no-cache && \
  apt-get update --fix-missing && \
  apt-get install -y --no-install-recommends \
  	  build-essential libfreetype6-dev libpng12-dev libzmq3-dev \
 	  pkg-config python python3-dev rsync software-properties-common \
	  unzip libgtk2.0-0 tcl-dev tk-dev \
	  wget bzip2 ca-certificates \
  	  libglib2.0-0 libxext6 libsm6 libxrender1 \
	  git mercurial subversion curl grep sed dpkg && \
  echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
  wget --quiet https://repo.continuum.io/archive/Anaconda3-4.2.0-Linux-x86_64.sh -O ~/anaconda.sh && \
  /bin/bash ~/anaconda.sh -b -p /opt/conda && \
  rm ~/anaconda.sh && \
  TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
  curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
  dpkg -i tini.deb && \
  rm tini.deb && \
  apt-get clean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* && \
  export PATH=/opt/conda/bin:$PATH && \
  conda install pip -y && \
  conda install -c menpo opencv3 -y && \
  pip install tensorflow-gpu && \
  pip install keras && \
  apt-get clean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* && \
  chmod +x /run_jupyter.sh && \
  conda clean -tp -y && \
  ln -s /usr/local/cuda/lib64/libcudnn.so.5 /usr/local/cuda/lib64/libcudnn.so

EXPOSE 6006  # TensorBoard
EXPOSE 8888  # Jupyter
EXPOSE 4567  # Flask Server

ENV PATH=/opt/conda/bin:$PATH

ENTRYPOINT [ "/usr/bin/tini", "--" ]

CMD ["/run_jupyter.sh"]
