#!/bin/bash

set -euo pipefail

export CFLAGS="${CFLAGS:-} -march=native -lm -lz"
export LDFLAGS="${LDFLAGS:-} -lz"
export CXXFLAGS="${CXXFLAGS:-} -march=native -lm -lz"

# Get processor count (Linux or macOS)
MJOBS=$(getconf _NPROCESSORS_ONLN 2> /dev/null) || MJOBS=""

if [ -z "$MJOBS" ]; then
  # FreeBSD, fallback to 4 if fails
  MJOBS=$(getconf NPROCESSORS_ONLN 2> /dev/null) || MJOBS="4"
fi

if [ ! -d jetson-ffmpeg ]; then
  git clone https://github.com/Keylost/jetson-ffmpeg
fi

if ! pkg-config --exists nvmpi; then
  echo 'Building nvmpi because nvmpi could not be found with pkg-config'
  pushd jetson-ffmpeg
    mkdir build
    pushd build
      cmake ..
      make -j "$MJOBS"
      sudo make install
      sudo ldconfig
    popd
  popd
else
  echo 'Skipping installation of nvmpi'
fi

if ! pkg-config --exists nvmpi; then
  echo 'Could not find nvmpi even after installing it!'
  exit 1
fi

export PKG_CONFIG_PATH="$(pwd)/ffmpeg-build-script/workspace/lib/pkgconfig:$(pwd)/ffmpeg-build-script/workspace/usr/lib/pkgconfig"
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
    --extra-ldflags="-L/usr/local/cuda/lib64 -L$WORKSPACE/lib" \
    --extra-libs="-lpthread -lm -lz" \
    --pkgconfigdir="$WORKSPACE/lib/pkgconfig" \
    --pkg-config-flags="--static" \
    --prefix="${WORKSPACE}" \
    --enable-ffnvcodec \
    --disable-cuvid \
    --disable-nvdec \
    --disable-nvenc \
    --enable-nvmpi \
    --enable-openssl \
    --enable-libdav1d \
    --enable-libsvtav1 \
    --enable-librav1e \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libxvid \
    --enable-libvidstab \
    --enable-libaom \
    --enable-libzimg \
    --enable-lv2 \
    --enable-libopencore_amrnb \
    --enable-libopencore_amrwb \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libvorbis \
    --enable-libtheora \
    --enable-libfdk-aac \
    --enable-libwebp \
    --enable-libsrt \
    --enable-cuda-nvcc \
    --enable-libnpp \
    --nvccflags="-gencode arch=compute_53,code=sm_53"

  make -j "$MJOBS"
popd

echo 'Done! Your binaries are located in directory `ffmpeg`'
