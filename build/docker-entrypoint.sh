#!/bin/bash

# configure login for the docker hub
# we fetch the credentials from our internal vault (i am using vault now because my setup is running via rancher and not via swarm so no fancy docker secrets)

# authenticate against the vault
ACCESS_TOKEN=$(curl -X POST \
     -d "{\"role_id\":\"${VAULT_ROLE_ID}\",\"secret_id\":\"$VAULT_SECRET_ID\"}" \
     ${VAULT_SERVER}/v1/auth/approle/login | jq -r .auth.client_token)

# write the private key file for git
curl -X GET -H "X-Vault-Token:${ACCESS_TOKEN}" ${VAULT_SERVER}/v1/${VAULT_SECRET_GITHUB_KEY} | jq -r .data.value > ${GO_HOME}/.ssh/id_rsa
chown go:go ${GO_HOME}/.ssh/id_rsa
chmod 0600 ${GO_HOME}/.ssh/id_rsa

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
sed -i "s/export RANCHER_ACCESS_KEY=.*/export RANCHER_ACCESS_KEY=${access}/" ${GO_HOME}/.rancher
sed -i "s/export RANCHER_SECRET_KEY=.*/export RANCHER_SECRET_KEY=${secret}/" ${GO_HOME}/.rancher
chown go:go ${GO_HOME}/.rancher
chmod 0600 ${GO_HOME}/.rancher
unset vault_data
unset access
unset secret

# after configuring the agent execute the original entrypoint
exec /docker-entrypoint.sh