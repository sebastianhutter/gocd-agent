#!/bin/bash


# authenticate against docker hub
docker_user=$(cat /run/secrets/docker_user)
docker_pass=$(cat /run/secrets/docker_pass)
su -l go /bin/sh -c "docker login --username ${docker_user} --password ${docker_pass}"
unset docker_user
unset docker_pass