#!/bin/sh

set -e

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  patch cmake make g++ binutils file
