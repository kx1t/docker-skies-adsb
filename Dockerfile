# hadolint global ignore=DL3008,SC2086,SC2039,SC2068,DL3003,DL3013
FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

#LABEL org.opencontainers.image.source = "https://github.com/sdr-enthusiasts/docker-skies-adsb"

ENV BASH_ENV=/home/.bash_env \
    __VITE_ADDITIONAL_SERVER_ALLOWED_HOSTS=true

ARG BASH_ENV=/home/.bash_env 

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

RUN \
    # define required packages
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    PIP_PACKAGES=() && \
    KEPT_PACKAGES+=(nano) && \
    KEPT_PACKAGES+=(curl) && \
    KEPT_PACKAGES+=(python3-minimal) && \
    KEPT_PACKAGES+=(python3-pip) && \
    TEMP_PACKAGES+=(git) && \
    KEPT_PACKAGES+=(curl) && \
    KEPT_PACKAGES+=(unzip) && \
    KEPT_PACKAGES+=(python3-flask) && \
    KEPT_PACKAGES+=(python3-flask-cors) && \
    KEPT_PACKAGES+=(python3-geopandas) && \
    KEPT_PACKAGES+=(python3-requests) && \
    KEPT_PACKAGES+=(python3-rtree) && \
    KEPT_PACKAGES+=(python3-websockify) && \
    PIP_PACKAGES+=(osmtogeojson) && \
    #
    # install packages
    apt-get update && \
    apt-get install -q -o Dpkg::Options::="--force-confnew" -y --no-install-recommends  --no-install-suggests \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    pip3 install --no-cache-dir --break-system-packages "${PIP_PACKAGES[@]}" && \
    #
    #
    # Install NVM:
    touch "${BASH_ENV}" && \
    echo '. "${BASH_ENV}"' >> /home/.bashrc && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | PROFILE="${BASH_ENV}" bash && \
    echo node > .nvmrc && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install || true && \
    nvm install node || true && \
    # Clone skies-adsb from github:
    git clone --depth=1 https://github.com/machineinteractive/skies-adsb.git && \
    cd skies-adsb && \
    # Install stuff:
    npm install && \
    cp docs/dot-env-template src/.env && \
    cp docs/flask-config-template.json flask/config.json && \
    mkdir -p /skies-adsb/.venv/bin && \
    touch /skies-adsb/.venv/bin/activate && \
    # add files from the build container:
    echo "alias dir=\"ls -alsv\"" >> /root/.bashrc && \
    echo "alias nano=\"nano -l\"" >> /root/.bashrc && \
    # Add Container Version:
    repo="kx1t/docker-skies-adsb" && \
    branch="dev" && \
    commit="$(curl -sSL -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/$repo/commits/$branch)" && \
    c_sha="$(sed -n 's|^\s*\"sha\":\s*\"\([0-9a-f]\{7\}\).*$|\1|p' <<< "$commit" | head -n 1)" && \
    c_date="$(sed -n 's|^\s*\"date\":\s*\"\([^\"]*\).*$|\1|p' <<< "$commit" | head -n 1)" && \
    echo "${repo##*/}_${c_sha}_${c_date}" > /.CONTAINER_VERSION && \
    echo Uninstalling $TEMP_PACKAGES && \
    apt-get remove -y -q ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -y && \
    apt-get clean -y -q && \
    rm -rf \
    /src/* \
    /var/cache/* \
    /tmp/* \
    /var/lib/apt/lists/* \
    /.dockerenv \
    /git

COPY rootfs/ /

# Add healthcheck
# HEALTHCHECK --start-period=60s --interval=600s --timeout=60s CMD /healthcheck/healthcheck.sh
