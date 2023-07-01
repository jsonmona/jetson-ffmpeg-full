#!/bin/bash

set -euo pipefail

export CFLAGS="${CFLAGS:-} -march=native"
export CXXFLAGS="${CXXFLAGS:-} -march=native"

if ! pkg-config --exists nvmpi; then
  echo 'Building nvmpi because nvmpi could not be found with pkg-config'
  pushd jetson-ffmpeg
    mkdir build
    pushd build
      cmake ..
      make
      sudo make install
      sudo ldconfig
    popd
  popd
fi

if ! pkg-config --exists nvmpi; then
  echo 'Could not find nvmpi even after installing it!'
  exit 1
fi

export PKG_CONFIG_PATH="$(pwd)/ffmpeg-build-script/workspace/lib/pkgconfig"
export WORKSPACE="$(pwd)/ffmpeg-build-script/workspace"

if [ ! -d ffmpeg-build-script ]; then
  echo 'Downloading ffmpeg-build-script...'
  git clone -b v1.45 https://github.com/markus-perl/ffmpeg-build-script
  pushd ffmpeg-build-script
    echo 'Patching ffmpeg-build-script...'
    git apply ../ffmpeg-build-script.diff
  popd
else
  echo 'Using already existing ffmpeg-build-script!'
fi

pushd ffmpeg-build-script
  ./build-ffmpeg --enable-gpl-and-non-free --build
popd

if [ ! -d jetson-ffmpeg ]; then
  git clone https://github.com/Keylost/jetson-ffmpeg
fi

if [ ! -d ffmpeg ]; then
  git clone git://source.ffmpeg.org/ffmpeg.git -b release/6.0 --depth=1
  pushd ffmpeg
    echo 'Patching ffmpeg...'
    git apply ../jetson-ffmpeg/ffmpeg_patches/ffmpeg6.0_nvmpi.patch
  popd
fi

pushd ffmpeg
  ./configure \
    --enable-gpl \
    --enable-nonfree \
    --disable-debug \
    --disable-doc \
    --disable-shared \
    --enable-pthreads \
    --enable-static \
    --enable-small \
    --enable-version3 \
    --extra-cflags="${CFLAGS} -I/usr/local/cuda/include" \
    --extra-ldflags="-L/usr/local/cuda/lib64" \
    --extra-libs="-lpthread -lm" \
    --pkgconfigdir="$WORKSPACE/lib/pkgconfig" \
    --pkg-config-flags="--static" \
    --prefix="${WORKSPACE}" \
    --disable-ffnvcodec \
    --disable-cuvid \
    --disable-nvdec \
    --disable-nvenc \
    --enable-nvmpi \
    --enable-libnpp
popd

