# ARG RISK=edge
# ARG UBUNTU=bionic

# FROM ubuntu:$UBUNTU as builder
# ARG RISK
# ARG UBUNTU
# RUN echo "Building snapcraft:$RISK in ubuntu:$UBUNTU"

# # Grab dependencies
# RUN apt-get update
# RUN apt-get dist-upgrade --yes
# RUN apt-get install --yes \
#   curl \
#   jq \
#   squashfs-tools

# # Grab the core snap (for backwards compatibility) from the stable channel and
# # unpack it in the proper place.
# RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core' | jq '.download_url' -r) --output core.snap
# RUN mkdir -p /snap/core
# RUN unsquashfs -d /snap/core/current core.snap

# # Grab the core18 snap (which snapcraft uses as a base) from the stable channel
# # and unpack it in the proper place.
# RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core18' | jq '.download_url' -r) --output core18.snap
# RUN mkdir -p /snap/core18
# RUN unsquashfs -d /snap/core18/current core18.snap

# # Grab the core20 snap (which snapcraft uses as a base) from the stable channel
# # and unpack it in the proper place.
# RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core20' | jq '.download_url' -r) --output core20.snap
# RUN mkdir -p /snap/core20
# RUN unsquashfs -d /snap/core20/current core20.snap

# # Grab the snapcraft snap from the $RISK channel and unpack it in the proper
# # place.
# RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/snapcraft?channel='$RISK | jq '.download_url' -r) --output snapcraft.snap
# RUN mkdir -p /snap/snapcraft
# RUN unsquashfs -d /snap/snapcraft/current snapcraft.snap

# # Fix Python3 installation: Make sure we use the interpreter from
# # the snapcraft snap:
# RUN unlink /snap/snapcraft/current/usr/bin/python3
# RUN ln -s /snap/snapcraft/current/usr/bin/python3.* /snap/snapcraft/current/usr/bin/python3
# RUN echo /snap/snapcraft/current/lib/python3.*/site-packages >> /snap/snapcraft/current/usr/lib/python3/dist-packages/site-packages.pth

# # Create a snapcraft runner (TODO: move version detection to the core of
# # snapcraft).
# RUN mkdir -p /snap/bin
# RUN echo "#!/bin/sh" > /snap/bin/snapcraft
# RUN snap_version="$(awk '/^version:/{print $2}' /snap/snapcraft/current/meta/snap.yaml | tr -d \')" && echo "export SNAP_VERSION=\"$snap_version\"" >> /snap/bin/snapcraft
# RUN echo 'exec "$SNAP/usr/bin/python3" "$SNAP/bin/snapcraft" "$@"' >> /snap/bin/snapcraft
# RUN chmod +x /snap/bin/snapcraft

# # Multi-stage build, only need the snaps from the builder. Copy them one at a
# # time so they can be cached.
# FROM ubuntu:$UBUNTU
# COPY --from=builder /snap/core /snap/core
# COPY --from=builder /snap/core18 /snap/core18
# COPY --from=builder /snap/core20 /snap/core20
# COPY --from=builder /snap/snapcraft /snap/snapcraft
# COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

# # Generate locale and install dependencies.
# RUN apt-get update && apt-get dist-upgrade --yes && apt-get install --yes snapd sudo locales && locale-gen en_US.UTF-8

# # Set the proper environment.
# ENV LANG="en_US.UTF-8"
# ENV LANGUAGE="en_US:en"
# ENV LC_ALL="en_US.UTF-8"
# ENV PATH="/snap/bin:/snap/snapcraft/current/usr/bin:$PATH"
# ENV SNAP="/snap/snapcraft/current"
# ENV SNAP_NAME="snapcraft"
# ENV SNAP_ARCH="amd64"

FROM myroslavmail/snapcraft:stable

#install node, npm, and git

RUN set -uex; \
  apt-get update; \
  apt-get install -y ca-certificates curl gnupg; \
  mkdir -p /etc/apt/keyrings; \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
  | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg; \
  NODE_MAJOR=16; \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
  > /etc/apt/sources.list.d/nodesource.list; \
  apt-get -qy update; \
  apt-get -qy install nodejs;


RUN apt-get -y install git

# set working directory
WORKDIR /app

# add `/app/node_modules/.bin` to $PATH
ENV PATH /app/node_modules/.bin:$PATH


# install app dependencies
COPY package.json ./
COPY package-lock.json ./
RUN npm install

# RUN apt-get install -y snapcraft

# RUN cat /snap/bin/snapcraft
# RUN sudo snapcraft

ENV PATH="/snap/bin:$PATH"
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAP_ARCH="amd64"


# add app
COPY . ./
# RUN snapcraft


# start app
RUN npm run make


