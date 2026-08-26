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
 && apt-get install -y --no-install-recommends tmux \
            git less ca-certificates jq wget unzip zip xz-utils bzip2 \
            build-essential python3-pip \
            tree file patch rsync openssh-client \
            dnsutils procps  \
            ripgrep fd-find shellcheck sqlite3 htop ncdu bat git-delta \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && npm install -g --ignore-scripts --min-release-age=0 @earendil-works/pi-coding-agent

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
RUN chmod +x /etc/services.d/pi/run
#  && SLICE_USER=${USER} | envsubst /etc/services.d/pi/run

# ╭――――――――――――――――――――╮
# │ CONFIG             │
# ╰――――――――――――――――――――╯
WORKDIR /home/${USER}/.pi/agent
RUN ln -fsv /mnt/volumes/data/auth.json . \
 && ln -fsv /mnt/volumes/data/extensions . \
 && ln -fsv /mnt/volumes/data/models-store.json . \
 && ln -fsv /mnt/volumes/data/sessions . \
 && ln -fsv /mnt/volumes/data/settings.json . \
 && ln -fsv /mnt/volumes/data/skills . 
WORKDIR /home/${USER}
RUN ln -fsv /mnt/volumes/data/files .
WORKDIR /
COPY home/slice/_tmux.conf /home/#{USER}/.tmux.conf
RUN chown ${USER}:${USER} -R /home/${USER}

# tmux config

