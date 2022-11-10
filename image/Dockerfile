# Copyright 2022 The MathWorks, Inc.
# Version 0.1
ARG MATLAB_RELEASE=r2022b
FROM mathworks/matlab-deps:${MATLAB_RELEASE}
LABEL maintainer="The MathWorks"

# Declare the global argument to use at the current build stage
ARG MATLAB_RELEASE

# Install MATLAB
ARG INSTALL_MATLAB=false
ARG ADDITIONAL_PRODUCTS
COPY product_lists /product_lists
RUN if [ ${INSTALL_MATLAB} = true ]; then \
        wget -q https://www.mathworks.com/mpm/glnxa64/mpm && \
        chmod +x mpm && \
        (./mpm install \
            --release=${MATLAB_RELEASE} \
            --destination=/matlab \
            --products $(cat /product_lists/${MATLAB_RELEASE}.txt) || \
            (echo "MPM Installation Failure. See below for more information:" && \
            cat /tmp/mathworks_root.log && false)) && \
        rm -f mpm mathworks_root.log && \
        ln -s /matlab/bin/matlab /usr/local/bin/matlab; \
    fi

# Install OpenSSH
RUN apt-get update \
    && apt-get install --yes --no-install-recommends openssh-client openssh-server

# Install curl
RUN apt-get install --yes --no-install-recommends curl

# Install kubectl
RUN curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
    | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install --yes kubectl

# Install helm
RUN apt-get install --yes gnupg \
    && curl https://baltocdn.com/helm/signing.asc | apt-key add - \
    && apt-get install --yes apt-transport-https \
    && echo "deb https://baltocdn.com/helm/stable/debian/ all main" \
    | tee /etc/apt/sources.list.d/helm-stable-debian.list \
    && sudo apt-get update \
    && sudo apt-get install --yes helm

# Set up ssh server
RUN mkdir --parents /var/run/sshd \
    && ssh-keygen -A \
    && sed --in-place 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config \
    && sed --in-place 's/#RSAAuthentication yes/RSAAuthentication yes/g' /etc/ssh/sshd_config \
    && sed --in-place 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config

# Copy ssh config
COPY ssh_config /config/ssh_config

# Copy shell scripts
COPY scripts/*.sh /scripts/

# Copy helm template for secondary workers of communicating jobs
COPY secondary-communicating-job /scripts/secondary-communicating-job

# Define entrypoint
ENTRYPOINT ["/bin/bash"]
