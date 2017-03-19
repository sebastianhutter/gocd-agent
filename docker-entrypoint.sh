#!/bin/bash

# configure login for the docker hub
# we fetch the credentials from our internal vault (i am using vault now because my setup is running via rancher and not via swarm so no fancy docker secrets)

# authenticate against the vault
ACCESS_TOKEN=$(curl -X POST \
     -d "{\"role_id\":\"${VAULT_ROLE_ID}\",\"secret_id\":\"$VAULT_SECRET_ID\"}" \
     ${VAULT_SERVER}/v1/auth/approle/login | jq -r .auth.client_token)

# write the private key file for git
curl -X GET -H "X-Vault-Token:${ACCESS_TOKEN}" ${VAULT_SERVER}/v1/${VAULT_SECRET_GITHUB_KEY} | jq -r .data.value > /var/go/.ssh/id_rsa
unset OUTPUT
chown go:go /var/go/.ssh/id_rsa
chmod 0600 /var/go/.ssh/id_rsa

# authenticate against docker hub
docker login \
  --username $(curl -X GET -H "X-Vault-Token:${ACCESS_TOKEN}" ${VAULT_SERVER}/v1/${VAULT_SECRET_DOCKER_USER} | jq -r .data.value) \
  --password $(curl -X GET -H "X-Vault-Token:${ACCESS_TOKEN}" ${VAULT_SERVER}/v1/${VAULT_SECRET_DOCKER_PASS} | jq -r .data.value)

# after configuring the agent execute the original entrypoint
exec /sbin/my_init