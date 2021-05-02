#!/bin/sh

if [ -z "$1" ] && [ -z "$2" ]; then
    echo "usage: $0 <openwrt version> <kernel vermagic> <arch, default x86/64>"
    exit
fi

OPENWRT_RELEASE=$1
KERNEL_VERMAGIC=$2
if [ -z "$3" ]; then ARCH="x86/64"; else ARCH=$3; fi

MAKEFLAG="V=s -j$(nproc)"

git clone --branch v$OPENWRT_RELEASE --depth 1 https://git.openwrt.org/openwrt/openwrt.git buildroot
cd buildroot

# Apply changes
git apply ../mellanox-inbox-driver.patch
sed -i -e "s/grep.*mkhash md5/echo '$KERNEL_VERMAGIC'/g" include/kernel-defaults.mk

# Prepare
wget https://downloads.openwrt.org/releases/$OPENWRT_RELEASE/targets/$ARCH/config.buildinfo -O .config
make defconfig

# Compiled
make toolchain/install $MAKEFLAG
make target/linux/compile $MAKEFLAG
make package/kernel/linux/compile $MAKEFLAG

# Copy compiled package
cp ./bin/targets/$ARCH/packages/kmod-mlx*.ipk ../
cd ../

# Clean up
rm -rf buildroot
