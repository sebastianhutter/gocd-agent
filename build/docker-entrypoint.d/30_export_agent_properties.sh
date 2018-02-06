#!/bin/bash

export GO_SERVER_URL=$(cat /run/secrets/securesiteurl)
export AGENT_AUTO_REGISTER_KEY=$(cat /run/secrets/autoregister)