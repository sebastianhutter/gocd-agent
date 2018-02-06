#!/bin/bash

# setup user permissions for docker sock
groupadd -g 1101 docker-rancheros
usermod -a -G docker-rancheros go

# authenticate against docker hub
docker_user=$(cat /run/secrets/docker-user)
docker_pass=$(cat /run/secrets/docker-pass)
su -l go /bin/sh -c "docker login --username ${docker_user} --password ${docker_pass}"
unset docker_user
unset docker_pass