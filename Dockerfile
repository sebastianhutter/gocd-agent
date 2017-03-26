FROM debian:jessie
MAINTAINER <mail@sebastian-hutter.ch>

# build arguments
ARG GOCD_AGENT_VERSION=17.3.0

# environment variables used for building and entrypoint
ENV GOCD_DATA=/var/lib/go-agent
ENV GOCD_HOME=/var/go
ENV GOCD_LOG=/var/log/go-agent
ENV GOCD_SCRIPT=/usr/share/go-agent
ENV DEFAULTS=/etc/default/go-agent

# additional scripts etc
ARG GAUCHO_VERSION=0.0.1

# install build requirements
RUN apt-get update \
  && apt-get install -y apt-transport-https ca-certificates curl software-properties-common \
  &&  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian \
    $(lsb_release -cs) \
    stable" \
  && curl -fsSL https://download.docker.com/linux/debian/gpg  | apt-key add - \
  && apt-get update \
  && apt-get install -y gettext jq docker-ce build-essential git httpie python-pip \
  && rm -rf /var/lib/apt/lists/*

# install requirements for the gocd agents
RUN echo "deb http://ftp.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list \
 && apt-get update \
 && apt-get install -y curl jq gettext apt-transport-https git \
 && apt-get install -y -t jessie-backports ca-certificates-java openjdk-8-jre-headless \
 && rm -rf /var/lib/apt/lists/*

# install the gocd agent
# the apt-cache command tries to get the correct debian package version form the
# specfiied gocd_server_version variable
RUN echo "deb https://download.gocd.io /" > /etc/apt/sources.list.d/gocd.list \
  && curl https://download.gocd.io/GOCD-GPG-KEY.asc | apt-key add - \
  && apt-get update \
  && apt-get install -y go-agent=$(apt-cache show go-server | grep "Version: ${GOCD_AGENT_VERSION}.*" | head -n 1 | awk '{print $2}') \
  && rm -rf /var/lib/apt/lists/*

# install gaucho script
RUN cd /tmp \
  && curl -LO https://github.com/sebastianhutter/gaucho/archive/${GAUCHO_VERSION}.tar.gz \
  && tar xzf ${GAUCHO_VERSION}.tar.gz \
  && pip install -r /tmp/gaucho-${GAUCHO_VERSION}/requirements.txt \
  && mv /tmp/gaucho-${GAUCHO_VERSION}/services.py /usr/local/bin/gaucho.py \
  && chmod +x /usr/local/bin/gaucho.py \
  && echo "export RANCHER_ACCESS_KEY=" >> ${GOCD_HOME}/.rancher \
  && echo "export RANCHER_SECRET_KEY=" >> ${GOCD_HOME}/.rancher \
  && cd / && rm -rf /tmp/*

# allow go user to access docker stuff
RUN usermod -a -G docker go

# install helper scripts
COPY build/scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# add entrypoint and ssh config
ADD build/docker-entrypoint.sh /docker-entrypoint.sh
ADD build/ssh.config ${GOCD_HOME}/.ssh/config
RUN chmod +x /docker-entrypoint.sh \
  && chown -R go:go ${GOCD_HOME}/.ssh

ENTRYPOINT ["/docker-entrypoint.sh"]
