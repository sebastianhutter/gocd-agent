#!/bin/bash
mkdir -p ${GOCD_HOME}/.ssh
ssh-keyscan github.com > ${GOCD_HOME}/.ssh/known_hosts
cp -f /run/secrets/ssh-key ${GOCD_HOME}/.ssh/id_rsa
chmod 0400 ${GOCD_HOME}/.ssh/id_rsa
chown -R go:go ${GOCD_HOME}/.ssh
