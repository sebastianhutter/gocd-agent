#!/bin/bash

# configure login for the docker hub
# we fetch the credentials from our internal vault (i am using vault now because my setup is running via rancher and not via swarm so no fancy docker secrets)

# authenticate against the vault
ACCESS_TOKEN=$(curl -X POST \
     -d "{\"role_id\":\"${VAULT_ROLE_ID}\",\"secret_id\":\"$VAULT_SECRET_ID\"}" \
     ${VAULT_SERVER}/v1/auth/approle/login | jq -r .auth.client_token)

# write the private key file for git
curl -X GET -H "X-Vault-Token:${ACCESS_TOKEN}" ${VAULT_SERVER}/v1/${VAULT_SECRET_GITHUB_KEY} | jq -r .data.value > ${GOCD_HOME}/.ssh/id_rsa
chown go:go ${GOCD_HOME}/.ssh/id_rsa
chmod 0600 ${GOCD_HOME}/.ssh/id_rsa

# authenticate against docker hub
docker_user=$(curl -X GET -H "X-Vault-Token:${ACCESS_TOKEN}" ${VAULT_SERVER}/v1/${VAULT_SECRET_DOCKER_USER} | jq -r .data.value)
docker_pass=$(curl -X GET -H "X-Vault-Token:${ACCESS_TOKEN}" ${VAULT_SERVER}/v1/${VAULT_SECRET_DOCKER_PASS} | jq -r .data.value)
su -l go /bin/sh -c "docker login --username ${docker_user} --password ${docker_pass}"
unset docker_user
unset docker_pass

# add the rancher api key and secret into the go users bashrc
vault_data=$(curl -X GET -H "X-Vault-Token:${ACCESS_TOKEN}" ${VAULT_SERVER}/v1/${VAULT_SECRET_RANCHER_API})
access=$(echo $vault_data | jq -r .data.key)
secret=$(echo $vault_data | jq -r .data.secret)
sed -i "s/export RANCHER_ACCESS_KEY=.*/export RANCHER_ACCESS_KEY=${access}/" ${GOCD_HOME}/.rancher
sed -i "s/export RANCHER_SECRET_KEY=.*/export RANCHER_SECRET_KEY=${secret}/" ${GOCD_HOME}/.rancher
chown go:go ${GOCD_HOME}/.rancher
chmod 0600 ${GOCD_HOME}/.rancher
unset vault_data
unset access
unset secret

# configure the go agent
# set the go server url
# delete the line first and then append the line (sed doesnt like the : in the url)
sed -i 's/GO_SERVER_URL=.*/d' "${DEFAULTS}"
echo "GO_SERVER_URL=${GO_SERVER_URL}" >> "${DEFAULTS}"

# set the auto registration key
if [ -n "${GOCD_AGENTAUTOREGISTERKEY}" ]; then
  mkdir -p "${GOCD_DATA}/config"
  echo "agent.auto.register.key=${GOCD_AGENTAUTOREGISTERKEY} > ${GOCD_DATA}/config/autoregister.properties"
  chown -R go:go "${GOCD_DATA}/config"
fi

# now start the agent
# we start the agent daemonized (see the /etc/defaults/go-agent DAEMON flag)
# to keep the container running we tail the go-cd server log files
su - go -c "${GOCD_SCRIPT}/agent.sh"
# we sleep 3 seconds to surpress the error message about missing logfiles
sleep 3
su - go -c "tail -qF ${GOCD_LOG}/go-agent-bootstrapper.out.log  ${GOCD_LOG}/go-agent-launcher.log"
