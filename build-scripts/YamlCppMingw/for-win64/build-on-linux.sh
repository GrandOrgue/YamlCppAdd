#!/bin/bash

set -e

BASE_DIR=$(dirname $0)
SRC_DIR=$(readlink -f $BASE_DIR/../../..)
echo SRC_DIR=$SRC_DIR

DEBIAN_PKG_NAME=libyaml-cpp-mingw-w64
VERSION=${1:-0.6.2}
BUILD_VERSION=${2:-0.go}
PARALLEL_PRMS="-j$(nproc)"

BUILD_DIR=`pwd`/build/win64
mkdir -p $BUILD_DIR
pushd $BUILD_DIR

rm -rf $BUILD_DIR/*
mkdir $BUILD_DIR/src
cp -r $SRC_DIR/submodules/YamlCpp/* $BUILD_DIR/src

pushd $BUILD_DIR/src
patch -p1 <$SRC_DIR/patches/mingw-pkgconfig.patch
popd
    
. $BASE_DIR/set-mingw-vars.sh

#  -DLIB_INSTALL_DIR=$LIB_INSTALL_DIR \

cmake \
  -DCMAKE_INSTALL_PREFIX=/usr/x86_64-w64-mingw32 \
  -DYAML_CPP_BUILD_TESTS=OFF \
  -DYAML_CPP_BUILD_TOOLS=OFF \
  $CMAKE_MINGW_PRMS \
  . $BUILD_DIR/src
make $PARALLEL_PRMS

# install
PKG_DIR=$BUILD_DIR/${DEBIAN_PKG_NAME}_${VERSION}-${BUILD_VERSION}_all
make DESTDIR=$PKG_DIR install


mkdir $PKG_DIR/DEBIAN

cat >$PKG_DIR/DEBIAN/control <<EOF
Package: $DEBIAN_PKG_NAME
Version: $VERSION-$BUILD_VERSION
Architecture: all
Maintainer: Oleg Samarin <osamarin68@gmail.com>
Description: This is yaml-cpp for cross-compiling for for Win64
EOF

dpkg-deb --build --root-owner-group $PKG_DIR

popd

