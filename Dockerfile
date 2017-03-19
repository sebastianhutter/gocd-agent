FROM gocd/gocd-agent

# install build requirements
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
  &&  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable" \
  && apt-get update \
  && apt-get install -y gettext jq docker-ce \
  && rm -rf /var/lib/apt/lists/*

ADD docker-entrypoint.sh /docker-entrypoint.sh
ADD ssh.config /var/go/.ssh/config
RUN chmod +x /docker-entrypoint.sh \
  && chown -R go:go /var/go/.ssh

ENTRYPOINT ["/docker-entrypoint.sh"]
