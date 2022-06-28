FROM rockylinux/rockylinux:8.6.20220515

ARG python_version=3.8.13

RUN dnf install -y \
  gzip \
  wget \
  make \
  gcc \
  zlib-devel \
  openssl-devel \
  vim \
  libffi-devel

RUN yum -y update && yum clean all

RUN wget https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz -O /tmp/python.tgz && \
    tar xvf /tmp/python.tgz -C /tmp && \
    cd /tmp/Python-${python_version} && \
    ./configure --enable-optimizations && \
    make install

RUN /usr/local/bin/python3 -m pip install --upgrade pip

RUN rm /tmp/python.tgz && \
    rm -rf /tmp/Python-${python_version}

