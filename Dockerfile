# An incomplete base Docker image for running JupyterHub
#
# Add your configuration to create a complete derivative Docker image.
#
# Include your configuration settings by starting with one of two options:
#
# Option 1:
#
# FROM jupyterhub/jupyterhub:latest
#
# And put your configuration file jupyterhub_config.py in /srv/jupyterhub/jupyterhub_config.py.
#
# Option 2:
#
# Or you can create your jupyterhub config and database on the host machine, and mount it with:
#
# docker run -v $PWD:/srv/jupyterhub -t jupyterhub/jupyterhub
#
# NOTE
# If you base on jupyterhub/jupyterhub-onbuild
# your jupyterhub_config.py will be added automatically
# from your docker directory.

# multi-stage build
# first stage: build wheel
ARG UBUNTU_VERSION=18.04
FROM ubuntu:$UBUNTU_VERSION
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends python3-wheel python3-pip python3-setuptools nodejs npm

ADD . /src/jupyterhub
WORKDIR /src/jupyterhub
RUN python3 -m pip wheel -v --no-deps .

FROM ubuntu:$UBUNTU_VERSION

# install nodejs, utf8 locale, set CDN because default httpredir is unreliable
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends python3-setuptools python3-pip nodejs npm && \
    apt-get purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV LANG C.UTF-8
COPY --from=0 /src/jupyterhub/jupyterhub*.whl /src/jupyterhub/
COPY dockerfiles/requirements.txt /src/jupyterhub/requirements.txt
RUN python3 -m pip install --no-cache /src/jupyterhub/jupyterhub*.whl -r /src/jupyterhub/requirements.txt

ARG CHP_VERSION=4.1.*
RUN npm install -g configurable-http-proxy@${CHP_VERSION} && \
    rm -rf ~/.npm

RUN mkdir -p /srv/jupyterhub/
COPY dockerfiles/jupyterhub_config.py /srv/jupyterhub/jupyterhub_config.py

WORKDIR /srv/jupyterhub/
EXPOSE 8000
LABEL org.jupyter.service="jupyterhub"
LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
CMD ["jupyterhub"]
