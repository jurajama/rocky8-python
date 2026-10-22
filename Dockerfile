FROM rockylinux/rockylinux:8.10.20240528

ARG python_version=3.11.14

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

# Pick up the latest ca-certificates (eMudhra/emSign CA incident, CVE-2026-113470) and rebuild the trust store.
RUN yum -y update --nobest && yum clean all && update-ca-trust extract

RUN wget https://www.python.org/ftp/python/${python_version}/Python-${python_version}.tgz -O /tmp/python.tgz && \
    tar xvf /tmp/python.tgz -C /tmp && \
    cd /tmp/Python-${python_version} && \
    ./configure --enable-optimizations && \
    make install

# The pip bundled with Python (ensurepip) vendors an outdated certifi that still trusts the compromised emSign CAs,
# and pip always loads its vendored certifi, so using it to download the fix would not be safe. Fetch the fixed pip
# wheel with the system trust store (wget) instead, verify its SHA256 and install it from the local file.
# See https://discuss.python.org/t/information-for-python-users-regarding-emudhra-emsign-ca-certificate-security-incident/109576
ARG pip_version=26.2.2
ARG pip_sha256=fd7f4dfa8190e014013b9f08f3e973f4e4c26ffd179a204895533a7254813a70
RUN wget -O /tmp/pip-${pip_version}-py3-none-any.whl \
      https://files.pythonhosted.org/packages/3f/06/3e4420302363fbb71be3c7f35ce042f54bfca330e3e66b3a2e3c4cca579f/pip-${pip_version}-py3-none-any.whl && \
    echo "${pip_sha256}  /tmp/pip-${pip_version}-py3-none-any.whl" | sha256sum -c - && \
    /usr/local/bin/python3 -m pip install --no-index --upgrade /tmp/pip-${pip_version}-py3-none-any.whl && \
    # Python -m venv bootstraps pip from the wheel bundled in ensurepip, so replace that one with the fixed wheel too.
    ensurepip_dir=$(/usr/local/bin/python3 -c 'import ensurepip, os; print(os.path.dirname(ensurepip.__file__))') && \
    rm -f ${ensurepip_dir}/_bundled/pip-*.whl && \
    cp /tmp/pip-${pip_version}-py3-none-any.whl ${ensurepip_dir}/_bundled/ && \
    sed -i "s/^_PIP_VERSION = .*/_PIP_VERSION = \"${pip_version}\"/" ${ensurepip_dir}/__init__.py && \
    rm /tmp/pip-${pip_version}-py3-none-any.whl

RUN rm /tmp/python.tgz && \
    rm -rf /tmp/Python-${python_version}

