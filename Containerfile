FROM docker.io/gautada/node:22.23.2

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
# --min-release-age=0 tells npm: “don’t require a package version to have been
# published for any minimum amount of time.”
# Why use it: if your npm config enforces a delay like 1–7 days before newly
# published packages can be installed, 0 overrides that and lets you install
# the newest release immediately.
# Why not use it: that delay is a supply-chain safety feature. Waiting before
# accepting brand-new releases gives the ecosystem time to catch malicious or
# compromised packages.
# So: use it only if an existing release-age policy is blocking a package you
# intentionally need right now. Otherwise leave it off.
#
# hadolint ignore=DL3016
RUN apt-get update \
 && apt-get upgrade --yes \
 && apt-get install -y --no-install-recommends tmux \
            git less ca-certificates jq wget unzip zip xz-utils bzip2 \
            build-essential python3-pip \
            tree file patch rsync \
            dnsutils procps  \
            ripgrep fd-find shellcheck sqlite3 htop ncdu bat git-delta \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && npm install -g --ignore-scripts --min-release-age=0 \
    @earendil-works/pi-coding-agent \
 && npm install -g --min-release-age=0  pi-web-ui \
 && npm install -g --min-release-age=0 pi-slack-bridge


# ╭――――――――――――――――――――╮
# │ USER               │
# ╰――――――――――――――――――――╯
COPY usr/bin/container-version /usr/bin/container-version

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

# ╭――――――――――――――――――――╮
# │ CONFIG             │
# ╰――――――――――――――――――――╯
WORKDIR /home/${USER}/.pi/agent
RUN ln -fsv /mnt/volumes/data/auth.json . \
 && ln -fsv /mnt/volumes/data/extensions . \
 && ln -fsv /mnt/volumes/data/models-store.json . \
 && ln -fsv /mnt/volumes/data/sessions . \
 && ln -fsv /mnt/volumes/data/settings.json . \
 && ln -fsv /mnt/volumes/data/skills . \
 && ln -fsv /mnt/volumes/data/AGENTS.md . 
WORKDIR /home/${USER}
RUN ln -fsv /mnt/volumes/data/Workspace . \
 && ln -fsv /mnt/volumes/data/tmux.conf .tmux.conf
WORKDIR /
RUN chown ${USER}:${USER} -R /home/${USER}

# tmux config

