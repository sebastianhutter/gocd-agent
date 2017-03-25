FROM gocd/gocd-agent

ARG GAUCHO_VERSION=0.0.1

# install build requirements
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
  &&  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" \
  && apt-get update \
  && apt-get install -y gettext jq docker-ce build-essential httpie python-pip \
  && rm -rf /var/lib/apt/lists/*

# install gaucho script
RUN /tmp \
  && curl -LO https://github.com/sebastianhutter/gaucho/archive/${GAUCHO_VERSION}.tar.gz \
  && tar xzf ${GAUCHO_VERSION}.tar.gz \
  && pip install -r /tmp/gaucho-${GAUCHO_VERSION}/requirements.txt \
  && mv /tmp/gaucho-${GAUCHO_VERSION}/services.py /usr/local/bin/gaucho.py \
  && chmod +x /usr/local/bin/gaucho.py \
  && echo "export RANCHER_ACCESS_KEY=" >> /var/go/.rancher \
  && echo "export RANCHER_SECRET_KEY=" >> /var/go/.rancher \
  && rm -rf /tmp/*

# install helper scripts
COPY build/scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# add entrypoint and ssh config
ADD build/ddocker-entrypoint.sh /docker-entrypoint.sh
ADD build/ssh.config /var/go/.ssh/config
RUN chmod +x /docker-entrypoint.sh \
  && chown -R go:go /var/go/.ssh

ENTRYPOINT ["/docker-entrypoint.sh"]
