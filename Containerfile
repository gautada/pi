FROM docker.io/gautada/debian:13.6 as npm

RUN apt-get update \
 && apt-get upgrade --yes \
 && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get install -y --no-install-recommends nodejs \
 && corepack enable \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && echo "n8n@${IMAGE_VERSION}" \
 && npm install "n8n@${IMAGE_VERSION}" -g 


FROM npm

RUN which npm
# RUN curl -fsSL https://pi.dev/install.sh | sh





 # \
 # && ln -fsv /mnt/volumes/data/ /home/$USER/.n8n
# RUN curl -fsSL https://pi.dev/install.sh | sh
