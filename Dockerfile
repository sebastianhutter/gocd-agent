FROM gocd/docker-gocd-agent-debian-8:v17.3.0

ARG GAUCHO_VERSION=0.0.1

ENV GO_HOME=/home/go

# install build requirements
RUN apt-get update \
  && apt-get install -y apt-transport-https ca-certificates curl software-properties-common \
  &&  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian \
    $(lsb_release -cs) \
    stable" \
  && curl -fsSL https://download.docker.com/linux/debian/gpg  | apt-key add - \
  && apt-get update \
  && apt-get install -y gettext jq docker-ce build-essential httpie python-pip \
  && rm -rf /var/lib/apt/lists/*

# install gaucho script
RUN cd /tmp \
  && curl -LO https://github.com/sebastianhutter/gaucho/archive/${GAUCHO_VERSION}.tar.gz \
  && tar xzf ${GAUCHO_VERSION}.tar.gz \
  && pip install -r /tmp/gaucho-${GAUCHO_VERSION}/requirements.txt \
  && mv /tmp/gaucho-${GAUCHO_VERSION}/services.py /usr/local/bin/gaucho.py \
  && chmod +x /usr/local/bin/gaucho.py \
  && echo "export RANCHER_ACCESS_KEY=" >> ${GO_HOME}/.rancher \
  && echo "export RANCHER_SECRET_KEY=" >> ${GO_HOME}/.rancher \
  && cd / && rm -rf /tmp/*

# install helper scripts
COPY build/scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# add entrypoint and ssh config
ADD build/docker-entrypoint.sh /docker-entrypoint-custom.sh
ADD build/ssh.config ${GO_HOME}/.ssh/config
RUN chmod +x /docker-entrypoint-custom.sh \
  && chown -R go:go ${GO_HOME}/.ssh

ENTRYPOINT ["/docker-entrypoint-custom.sh"]
