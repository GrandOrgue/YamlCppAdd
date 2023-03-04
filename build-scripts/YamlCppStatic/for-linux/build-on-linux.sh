#!/bin/bash

set -e

SRC_DIR=`dirname $0`/../../..
PARALLEL_PRMS="-j$(nproc)"
DEBIAN_PKG_NAME=libyaml-cpp-static
VERSION=${1:-0.6.2}
BUILD_VERSION=${2:-0.go}
BUILD_DIR=`pwd`/build/linux

TMP_INSTALL_DIR=$BUILD_DIR/tmp_install
PKG_DIR=$BUILD_DIR/${DEBIAN_PKG_NAME}_${VERSION}-${BUILD_VERSION}_all
DEBIAN_HOST_MULTIARCH=x86_64-linux-gnu

mkdir -p $BUILD_DIR
rm -rf $BUILD_DIR/*
cp -ra $SRC_DIR/submodules/YamlCpp $BUILD_DIR/src

cd $BUILD_DIR/src
patch -p1 <$SRC_DIR/patches/install-cmake-dev-files.patch
cd $BUILD_DIR

mkdir $BUILD_DIR/build-static
cd $BUILD_DIR/build-static

LIB_INSTALL_DIR=lib/$DEBIAN_HOST_MULTIARCH

cmake \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DLIB_INSTALL_DIR=$LIB_INSTALL_DIR \
  -DYAML_CPP_BUILD_TESTS=OFF \
  -DYAML_CPP_BUILD_TOOLS=OFF \
  . $BUILD_DIR/src
make $PARALLEL_PRMS

# install
make DESTDIR=${TMP_INSTALL_DIR} install

cd $BUILD_DIR

mkdir -p ${PKG_DIR}/usr/${LIB_INSTALL_DIR}/cmake/yaml-cpp-static $PKG_DIR/usr/$LIB_INSTALL_DIR/pkgconfig

cp -a $TMP_INSTALL_DIR/usr/$LIB_INSTALL_DIR/cmake/yaml-cpp/* $PKG_DIR/usr/$LIB_INSTALL_DIR/cmake/yaml-cpp-static/
cp -a $TMP_INSTALL_DIR/usr/$LIB_INSTALL_DIR/pkgconfig/yaml-cpp.pc $PKG_DIR/usr/$LIB_INSTALL_DIR/pkgconfig/yaml-cpp-static.pc

mkdir -p $PKG_DIR/DEBIAN

cat >$PKG_DIR/DEBIAN/control <<EOF
Package: $DEBIAN_PKG_NAME
Version: $VERSION-$BUILD_VERSION
Architecture: all
Maintainer: Oleg Samarin <osamarin68@gmail.com>
Description: Cmake locators for building against yaml-ctl static libraries
EOF

dpkg-deb --build --root-owner-group $PKG_DIR
