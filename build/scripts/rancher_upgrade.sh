#!/bin/bash

#
# helper script to deploy a service by name to rancher
# the script needs three parameters
#
# 1: service name
# 2: docker image name to deploy
# 3: image version to deploy
#


echo "rancher_deploy.sh: start upgrade"
# load the environment variables
service_name=$1
image_name=$2
image_version=$3

[ -z "$service_name" ] && echo "rancher_deploy.sh: please specify service name. aborting." && exit 1
[ -z "$image_name" ] && echo "rancher_deploy.sh: please specify docker image name. aborting." && exit 1
[ -z "$image_version" ] && echo "rancher_deploy.sh: please specify docker image version. aborting." && exit 1

# load the necessary gaucho rancher config
echo "rancher_deploy.sh: source environment"
source /var/go/.rancher

# now get the service id from gaucho
echo "rancher_deploy.sh: get service id of ${service_name}"
service_id=$(gaucho.py id_of ${service_name})
[ -z "$service_id" ] && echo "rancher_deploy.sh: unable to retrieve service id of ${service_name}. aborting" && exit 1


# now execute the upgrade
echo "rancher_deploy.sh: upgrade service ${service_name} (${service_id}) with image ${image_name}:{$image_version}"
gaucho.py upgrade ${service_id} --imageUuid docker:${image_name}:${image_version} --auto_complete --timeout 300
# save the return value
deployment_state=$?

echo "rancher_deploy.sh: upgrade finised"
exit $deployment_state
