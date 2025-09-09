FROM ubuntu:22.04

SHELL ["/bin/bash", "-lc"]

RUN apt-get update && \
    apt-get install -y \
        build-essential \
        git \
        autoconf \
        automake \
        libtool \
        m4 \
        pkg-config \
        python3 \
        curl \
        libssl-dev \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/spack/spack /opt/spack

ENV SPACK_ROOT=/opt/spack
ENV PATH=$SPACK_ROOT/bin:$PATH
RUN echo ". /opt/spack/share/spack/setup-env.sh" >> /etc/bash.bashrc

RUN spack install gotcha
RUN spack install argobots
RUN spack install mochi-margo@0.13.1 ^libfabric fabrics=rxm,sockets,tcp
RUN spack install spath~mpi
RUN spack install openmpi
RUN spack install mercury

RUN git clone --branch dev https://github.com/LLNL/UnifyFS /opt/unifyfs && \
    cd /opt/unifyfs && git checkout v2.0

RUN . /opt/spack/share/spack/setup-env.sh && \
    spack load gotcha argobots mercury mochi-margo spath openmpi && \
    cd /opt/unifyfs && \
    mkdir install && \
    gotcha_install=$(spack location -i gotcha) && \
    spath_install=$(spack location -i spath) && \
    ./autogen.sh && \
    ./configure --prefix=/opt/unifyfs/install \
    CPPFLAGS="-I${gotcha_install}/include -I{spath_install}/include" LDFLAGS="-L${gotcha_install}/lib64 -L${spath_install}/lib64" && \
    make && make install

WORKDIR /work
CMD ["bash"]
