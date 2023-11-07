mkdir -p build

# this creates build/builder/buildroot/output/host directory
# with all stuff that we need to build library
# TODO: replace url with github url and pre-build buildroot in other project
#       probably multiple times for different boards
[ ! -f host.tar.gz ] && \
  wget https://static.parkingdp.online/host.tar.gz --no-check-certificate && \
  tar xf host.tar.gz

pushd build

  [ ! -d "camera_engine_rkaiq" ] && \
    git clone https://gitlab.com/rk3588_linux/linux/external/camera_engine_rkaiq.git --depth 1

  sudo apt install -y ninja-build m4 debhelper

  pushd camera_engine_rkaiq
    # load environment variables that we
    # need for successful build
    source build/linux/envsetup.sh 30

    TOOLCHAIN_FILE=$(pwd)/cmake/toolchains/aarch64_linux_buildroot.cmake
    export AIQ_BUILD_HOST_DIR=$(pwd)/../builder/buildroot/output/host
    cmake \
      -G "Ninja" \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo\
      -DARCH="aarch64" \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE \
      -DCMAKE_SKIP_RPATH=TRUE \
      -DCMAKE_INSTALL_PREFIX=/ \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=YES \
      -DISP_HW_VERSION=${ISP_HW_VERSION} \
    .
    echo "cmake result $?"

    ninja clean && ninja

    mkdir -p ../source/root/
    rm -rf ../source/root/*
    DESTDIR=../source/root/ ninja install

    mkdir -p ../source/root/etc/
    cp -r iqfiles/isp3x ../source/root/etc/iqfiles
  popd

  ln -sf ../../debian source/
  pushd source/
    dpkg-buildpackage -us -uc --host-arch arm64
  popd
popd
