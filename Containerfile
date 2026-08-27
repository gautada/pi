FROM docker.io/gautada/node:dev

# ╭――――――――――――――――――╮
# │ METADATA         │
# ╰――――――――――――――――――╯
LABEL org.opencontainers.image.title="pi"
LABEL org.opencontainers.image.description="A generic pi agent harness base container."
LABEL org.opencontainers.image.url="https://hub.docker.com/r/gautada/pi"
LABEL org.opencontainers.image.source="https://github.com/gautada/pi"
LABEL org.opencontainers.image.license="Liscense"

# RUN apt-get update \
#  && apt-get upgrade --yes \
#  && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
#  && apt-get install -y --no-install-recommends nodejs \
#  && corepack enable \
#  && apt-get clean \
#  && rm -rf /var/lib/apt/lists/* \
#  && echo "n8n@${IMAGE_VERSION}" \
#  && npm install "n8n@${IMAGE_VERSION}" -g 

# ╭――――――――――――――――――╮
# │ PACKAGES         │
# ╰――――――――――――――――――╯
# hadolint ignore=DL3016
RUN apt-get update \
 && apt-get upgrade --yes \
 && apt-get install -y --no-install-recommends tmux ripgrep fd-find \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && npm install -g --ignore-scripts --min-release-age=0 \
    @earendil-works/pi-coding-agent \
 && npm install -g --min-release-age=0 pi-web-ui
# WORKDIR /usr/lib/node_modules/pi-web-ui/node_modules/node-pty
# RUN PATH="/usr/lib/node_modules/npm/bin/node-gyp-bin:$PATH" node-gyp rebuild
# WORKDIR /

# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
# Rename the base user to this container user.
# Follows the same pattern as other gautada containers.
ARG USER=slice
RUN /usr/sbin/usermod -l $USER ryan \
 && /usr/sbin/usermod -d /home/$USER -m $USER \
 && /usr/sbin/groupmod -n $USER ryan \
 && PASSWORD="$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24)" \
 && printf '%s:%s\n' "$USER" "$PASSWORD" | /usr/sbin/chpasswd

# ╭――――――――――――――――――――╮
# │ SERVICE            │
# ╰――――――――――――――――――――╯
COPY etc/services.d/pi/run /etc/services.d/pi/run
COPY etc/services.d/pi-web-ui/run /etc/services.d/pi-web-ui/run
RUN chmod +x /etc/services.d/pi/run /etc/services.d/pi-web-ui/run
#  && SLICE_USER=${USER} | envsubst /etc/services.d/pi/run

WORKDIR /home/${USER}/.pi/agent
RUN ln -fsv /mnt/volumes/data/auth.json . \
 && ln -fsv /mnt/volumes/data/extensions . \
 && ln -fsv /mnt/volumes/data/models-store.json . \
 && ln -fsv /mnt/volumes/data/sessions . \
 && ln -fsv /mnt/volumes/data/settings.json .
WORKDIR /
RUN chown ${USER}:${USER} -R /home/${USER}

# tmux config

