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
DEB_HOST_MULTIARCH=$(dpkg-architecture -q DEB_HOST_MULTIARCH)

mkdir -p $BUILD_DIR
rm -rf $BUILD_DIR/*
cp -ra $SRC_DIR/submodules/YamlCpp $BUILD_DIR/src

cd $BUILD_DIR/src
patch -p1 <$SRC_DIR/patches/install-cmake-dev-files.patch
cd $BUILD_DIR

mkdir $BUILD_DIR/build-static
cd $BUILD_DIR/build-static

HOST_LIB_INSTALL_DIR=lib/$DEB_HOST_MULTIARCH

cmake \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DLIB_INSTALL_DIR=$HOST_LIB_INSTALL_DIR \
  -DYAML_CPP_BUILD_TESTS=OFF \
  -DYAML_CPP_BUILD_TOOLS=OFF \
  . $BUILD_DIR/src
make $PARALLEL_PRMS

# install
make DESTDIR=${TMP_INSTALL_DIR} install

cd $BUILD_DIR

# copy files to $PKG_DIR
SRC_LIB_DIR=$TMP_INSTALL_DIR/usr/$HOST_LIB_INSTALL_DIR
for TARGET_ARCH in amd64 i386 arm64 armhf; do
  DEB_TARGET_MULTIARCH=$(dpkg-architecture -A $TARGET_ARCH -q DEB_TARGET_MULTIARCH)
  TGT_LIB_DIR=$PKG_DIR/usr/lib/$DEB_TARGET_MULTIARCH
  mkdir -p $TGT_LIB_DIR/cmake/yaml-cpp-static $TGT_LIB_DIR/pkgconfig

  cp -a $SRC_LIB_DIR/cmake/yaml-cpp/* $TGT_LIB_DIR/cmake/yaml-cpp-static/
  cp -a $SRC_LIB_DIR/pkgconfig/yaml-cpp.pc $TGT_LIB_DIR/pkgconfig/yaml-cpp-static.pc

  # relpace all mentioning of $DEB_HOST_MULTIARCH to $DEB_TARGET_MULTIARCH
  if [[ $DEB_TARGET_MULTIARCH != $DEB_HOST_MULTIARCH ]]; then
    for F in $(grep -rl $DEB_HOST_MULTIARCH $TGT_LIB_DIR/*); do
      sed -i s/$DEB_HOST_MULTIARCH/$DEB_TARGET_MULTIARCH/g $F
    done
  fi
done

mkdir -p $PKG_DIR/DEBIAN

cat >$PKG_DIR/DEBIAN/control <<EOF
Package: $DEBIAN_PKG_NAME
Version: $VERSION-$BUILD_VERSION
Architecture: all
Maintainer: Oleg Samarin <osamarin68@gmail.com>
Description: Cmake locators for building against yaml-ctl static libraries
EOF

dpkg-deb --build --root-owner-group $PKG_DIR
