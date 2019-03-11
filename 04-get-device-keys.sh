#!/bin/bash

USERNAME=my-device

if [ -n "$1" ]; then
  USERNAME=$1
fi

oc extract secret/$USERNAME --keys=user.crt --to=- > user.crt
oc extract secret/$USERNAME --keys=user.key --to=- > user.key
oc extract secret/my-cluster-cluster-ca-cert --keys=ca.crt --to=- > ca.crt
