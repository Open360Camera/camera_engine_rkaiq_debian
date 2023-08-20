mkdir -p build

pushd build

  [ ! -d "camera_engine_rkaiq" ] && \
    git clone https://gitlab.com/rk3588_linux/linux/external/camera_engine_rkaiq.git --depth 1

  sudo apt install -y ninja-build m4 debhelper

  mkdir -p builder
  pushd builder
    git clone https://gitlab.com/rk3588_linux/rk/kernel.git --depth 1
    mkdir -p external
    pushd external
      git clone https://gitlab.com/rk3588_linux/linux/linux-rga.git
      git clone https://gitlab.com/rk3588_linux/linux/external/rktoolkit.git
    popd
    git clone https://gitlab.com/rk3588_linux/linux/buildroot.git
  popd

  cp ../configs/.config builder/buildroot/.config
  pushd builder/buildroot
    make -j 8
  popd

  pushd camera_engine_rkaiq
    # load environment variables that we
    # need for successful build
    source build/linux/envsetup.sh 30

    TOOLCHAIN_FILE=$(pwd)/cmake/toolchains/aarch64_linux_buildroot.cmake
    export AIQ_BUILD_HOST_DIR=$(pwd)/../builder/buildroot/output/host
    cmake \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo\
      -DARCH="aarch64" \
      -DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE \
      -DCMAKE_SKIP_RPATH=TRUE \
      -DCMAKE_INSTALL_PREFIX=/ \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=YES \
      -DISP_HW_VERSION=${ISP_HW_VERSION} \
    .

    ninja clean && ninja

    mkdir -p ../source/root/
    rm -rf ../source/root/*
    DESTDIR=../source/root/ ninja install

    mkdir -p ../source/root/etc/
    cp -r iqfiles/isp3x ../source/root/etc/iqfiles

    pushd ../source/
      dpkg-buildpackage -us -uc --host-arch amd64
    popd
  popd
popd
