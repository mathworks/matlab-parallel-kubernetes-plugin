# Copyright 2022-2023 The MathWorks, Inc.
ARG MATLAB_RELEASE=r2023b
ARG MATLAB_DEPS_IMAGE=mathworks/matlab-deps
FROM ${MATLAB_DEPS_IMAGE}:${MATLAB_RELEASE}
LABEL maintainer="The MathWorks"

# Declare the global argument to use at the current build stage
ARG MATLAB_RELEASE

# Install MATLAB
ARG INSTALL_MATLAB=false
ARG ADDITIONAL_PRODUCTS
COPY product_lists /product_lists
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN if [ "${INSTALL_MATLAB}" = true ]; then \
        wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \
        chmod +x mpm && \
        (./mpm install \
        --release="${MATLAB_RELEASE}" \
        --destination=/matlab \
        --products $(cat "/product_lists/${MATLAB_RELEASE}.txt") || \
        (echo "MPM Installation Failure. See below for more information:" && \
        cat /tmp/mathworks_root.log && false)) && \
        rm -f mpm mathworks_root.log && \
        ln -s /matlab/bin/matlab /usr/local/bin/matlab; \
        fi

# Install OpenSSH
RUN apt-get update && apt-get install --yes --no-install-recommends apt-transport-https && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install --yes --no-install-recommends openssh-client openssh-server && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

# Install libunwind on R2023a
RUN if [ "${MATLAB_RELEASE}" = "r2023a" ]; then \
        apt-get update && \
        apt-get install --yes --no-install-recommends libunwind8 && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
        fi

# Install libatomic on R2023b - needed by mpich 4
RUN if [ "${MATLAB_RELEASE}" = "r2023b" ]; then \
        apt-get update && \
        apt-get install --yes --no-install-recommends libatomic1 && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*; \
        fi

# Set up ssh server
RUN mkdir --parents /var/run/sshd && \
        ssh-keygen -A && \
        sed --in-place 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config && \
        sed --in-place 's/#RSAAuthentication yes/RSAAuthentication yes/g' /etc/ssh/sshd_config && \
        sed --in-place 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

# Copy ssh config
COPY ssh_config /config/ssh_config

# Copy shell scripts
COPY scripts/*.sh /scripts/

# Ensure wrapper script can be run by non-root user
RUN chmod 755 /scripts/runMatlabWithHostnameOverride.sh

# Define entrypoint
ENTRYPOINT ["/bin/sh"]
