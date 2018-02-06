FROM gocd/gocd-agent-alpine-3.7:v18.1.0

# environment variables
ENV GOCD_BASE=/godata
ENV GOCD_CONFIG=${GOCD_BASE}/config
ENV GOCD_LOGS=${GOCD_BASE}/logs
ENV GOCD_PIPELINES=${GOCD_BASE}/pipelines
ENV GOCD_HOME=/home/go

ENV APP_PKGS "shadow git curl docker py2-pip py-virtualenv jq make httpie"
ENV BUILD_PKGS "git curl make gcc g++ autoconf automake gzip libtool linux-headers python2-dev"

# install requirements
RUN apk add --no-cache ${APP_PKGS} \
  && apk add --no-cache -t buildpkg ${BUILD_PKGS} \
  && pip install --no-cache-dir --upgrade jinja2-cli[yaml] docker[tls] gnupg pyaml boto3 docker-compose \
  && ln -s /usr/bin/jinja2 /usr/bin/j2 \
  && curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o '/tmp/awscli-bundle.zip' \
  && cd /tmp ; unzip awscli-bundle.zip ; cd awscli-bundle ; ./install -i /usr/local ; cd \
  && rm -rf /tmp/awscli-bundle /tmp/awscli-bundle.zip \
  && apk del buildpkg

# add ssh config and entrypoint scripts
ADD build/docker-entrypoint.d/* /docker-entrypoint.d/
ADD build/scripts /scripts
ADD build/ssh.config ${GOCD_HOME}/.ssh/config
# set the correct permissions
RUN chmod +x /docker-entrypoint.d/* \
  && chmod +x /scripts/*\
  && chown -R go:go ${GOCD_HOME}/.ssh

