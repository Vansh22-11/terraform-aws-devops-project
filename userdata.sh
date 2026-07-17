#!/bin/bash

apt-get update -y

apt-get install -y git unzip curl wget

apt-get install -y awscli

echo "Terraform EC2 is ready." > /home/ubuntu/status.txt