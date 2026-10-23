FROM rockylinux/rockylinux:8.10.20240528

ARG python_version=3.11.17

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

# The pip bundled with Python (ensurepip, 24.0) vendors an outdated certifi that still trusts the compromised emSign CAs
# (eMudhra incident, CVE-2026-113470), so upgrade it. python -m venv bootstraps pip from the wheel bundled in ensurepip,
# so replace that wheel with the fixed one too, otherwise every new venv would start with the vulnerable pip.
# Remove this once the bundled pip of the Python release is 26.2.2 or later.
# See https://discuss.python.org/t/information-for-python-users-regarding-emudhra-emsign-ca-certificate-security-incident/109576
ARG pip_version=26.2.2
RUN /usr/local/bin/python3 -m pip download --no-deps "pip==${pip_version}" -d /tmp/pipwhl && \
    /usr/local/bin/python3 -m pip install --no-index --upgrade /tmp/pipwhl/pip-${pip_version}-py3-none-any.whl && \
    ensurepip_dir=$(/usr/local/bin/python3 -c 'import ensurepip, os; print(os.path.dirname(ensurepip.__file__))') && \
    rm -f ${ensurepip_dir}/_bundled/pip-*.whl && \
    cp /tmp/pipwhl/pip-${pip_version}-py3-none-any.whl ${ensurepip_dir}/_bundled/ && \
    sed -i "s/^_PIP_VERSION = .*/_PIP_VERSION = \"${pip_version}\"/" ${ensurepip_dir}/__init__.py && \
    rm -rf /tmp/pipwhl

RUN rm /tmp/python.tgz && \
    rm -rf /tmp/Python-${python_version}

