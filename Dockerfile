FROM gocd/gocd-agent

ARG GAUCHO_VERSION=0.0.1

# install build requirements
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
  &&  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" \
  && apt-get update \
  && apt-get install -y gettext jq docker-ce build-essential httpie python-pip \
  && cd /tmp \
  && curl -LO https://github.com/sebastianhutter/gaucho/archive/${GAUCHO_VERSION}.tar.gz \
  && tar xzf ${GAUCHO_VERSION}.tar.gz \
  && pip install -r /tmp/gaucho-${GAUCHO_VERSION}/requirements.txt \
  && mv /tmp/gaucho-${GAUCHO_VERSION}/services.py /usr/bin/gaucho.py \
  && chmod +x /usr/bin/gaucho.py \
  && echo "export RANCHER_URL=" >> /var/go/.bashrc \
  && echo "export RANCHER_ACCESS_KEY=" >> /var/go/.bashrc \
  && echo "export RANCHER_SECRET_KEY=" >> /var/go/.bashrc \
  && rm -rf /var/lib/apt/lists/* /tmp/*

ADD docker-entrypoint.sh /docker-entrypoint.sh
ADD ssh.config /var/go/.ssh/config
RUN chmod +x /docker-entrypoint.sh \
  && chown -R go:go /var/go/.ssh

ENTRYPOINT ["/docker-entrypoint.sh"]
