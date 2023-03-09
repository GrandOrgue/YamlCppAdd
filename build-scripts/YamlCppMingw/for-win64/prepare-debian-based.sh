#!/bin/bash

set -e

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  cmake \
  file \
  g++-mingw-w64-x86-64 \
  make \
  patch
