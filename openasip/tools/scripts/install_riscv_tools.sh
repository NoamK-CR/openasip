#!/bin/bash

TARGET_DIR=${1:?"Missing installation directory argument"}
ON_PATCH_FAIL="exit 1"

build_dir="riscv-tools-build"

rm -rf $build_dir
mkdir $build_dir
cd $build_dir

function eexit {
   echo "$1"
   exit 1
}

function install_gnu_toolchain {
    version=2023.07.07
    repository=https://github.com/riscv-collab/riscv-gnu-toolchain
    name=riscv-gnu-toolchain
    git clone $repository || eexit "git clone $name failed"
    cd $name
    git checkout $version || eexit "git checkout $name $version failed"
    ./configure --prefix=$TARGET_DIR --with-arch=rv32im \
        || eexit "configure $name failed"
    make -j$(nproc) || eexit "make $name failed"
    cd ..
}

function install_elf2hex {
    version=v20.08.00.00
    repository=https://github.com/sifive/elf2hex.git
    name=elf2hex
    git clone $repository || eexit "git clone $name failed"
    cd $name
    git checkout $version || eexit "git checkout $name $version failed"
    ./configure --prefix=$TARGET_DIR --with-arch=rv32im \
        || eexit "configure $name failed"
    make || eexit "make $name failed"
    make install || eexit "make install $name failed"
    cd ..
}

install_gnu_toolchain
install_elf2hex