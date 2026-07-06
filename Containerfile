FROM fedora:39

RUN mkdir /app 
WORKDIR /app

# 1. Install system tools & Python 3.11
RUN dnf update -y && dnf install -y \
    gcc \
    gcc-c++ \
    make \
    python3.11 \
    python3.11-devel \
    && dnf clean all

# 2. Copy and install from requirements.txt using Python 3.11
COPY requirements.txt .
RUN python3.11 -m ensurepip --default-pip && \
    python3.11 -m pip install --no-cache-dir --upgrade pip && \
    python3.11 -m pip install --no-cache-dir -r requirements.txt

# 3. Place custom logos 
COPY ./my_custom_logo.svg /usr/local/lib/python3.11/site-packages/cravat/websubmit/OC_COLOR.svg
COPY ./my_custom_logo.svg /usr/local/lib/python3.11/site-packages/cravat/websubmit/OC_LOGO_ONLY.svg

# 4. Setup internal data directory
RUN mkdir -p /opt/cravat_data
RUN oc config md /opt/cravat_data

# 5. Download base mappers
RUN oc module install-base

## Project tracking
EXPOSE 8000

# 6. Overwrites original yml files with the new port
RUN CONFIG_PATH=$(oc config system | head -n 1 | awk '{print $NF}' | sed 's,conf/cravat-system.yml,,g')

COPY ./cravat.yml ${CONFIG_PATH}/cravat.yml
COPY ./cravat.yml ${CONFIG_PATH}/conf/cravat.yml

# Set up the storage for the jobs:
RUN mkdir -p /data/jobs

# Set up storage path in system config file:
RUN SYSTEM_CONFIG=$(oc config system | head -n 1 | awk '{print $NF}') && \
    sed -i 's,^jobs_dir:.*,jobs_dir: /data/jobs,g' "${SYSTEM_CONFIG}"

# 7. Set the startup launch sequence
ENTRYPOINT ["oc"]
