#!/bin/bash
set -e

echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

apt-get update -y && apt-get upgrade -y

apt-get install git gitlab-runner -y

