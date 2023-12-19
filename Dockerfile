ARG ARCH=
FROM ${ARCH}rockylinux:8.9.20231119

ARG python_version=3.11.7

RUN dnf install -y \
  findutils \
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

