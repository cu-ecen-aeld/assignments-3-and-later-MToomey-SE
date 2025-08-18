#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

home_dir=$(pwd)
OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

if [ -f $OUTDIR ]
then
    # File exists, is not a directory    
    echo "  Error: $OUTDIR is a file"
    exit 1    
else
    if ! [ -d $OUTDIR ]
    then
        # Directory does not exist, try to create it
        mkdir -p ${OUTDIR}
        if [$? -ne 0]
        then
            echo "  Error: Could not create directory $OUTDIR"
            exit 1    
        fi
    fi
fi

if [ -d $OUTDIR ]
then
    echo "Directory OK: $OUTDIR"
    ls -la $OUTDIR
fi

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    echo "Build the kernel:"
    make defconfig
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- mrproper
    make ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- defconfig
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- all
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- modules
    make -j4 ARCH=arm64 CROSS_COMPILE=aarch64-none-linux-gnu- dtbs
fi

echo "Adding the Image in $OUTDIR"
cp $OUTDIR/linux-stable/arch/arm64/boot/Image $OUTDIR 
cp $OUTDIR/linux-stable/arch/arm64/boot/Image.gz $OUTDIR

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

mkdir rootfs
cd rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log
cd ..

# Create necessary base directories

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

echo "my cc is $CROSS_COMPILE"
# Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} 
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | grep "program interpreter"
${CROSS_COMPILE}readelf -a "${OUTDIR}/rootfs/bin/busybox" | grep "Shared library"

# Add library dependencies to rootfs
export SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)
echo "my sysr is $SYSROOT"
echo "my sysr libclib is $SYSROOT/lib"
echo "my sysr libclib64 is $SYSROOT/lib64"

cd ${OUTDIR}/rootfs
cp -a $SYSROOT/lib/ld-linux-aarch64.so.1 lib
cp -a $SYSROOT/lib64/libm.so.6 lib64
cp -a $SYSROOT/lib64/libresolv.so.2 lib64
cp -a $SYSROOT/lib64/libc.so.6 lib64

# Make device nodes
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 600 dev/console c 5 1
ls -l dev

# Clean and build the writer utility
cd $home_dir
make clean 
make CROSS_COMPILE=${CROSS_COMPILE}
ls writer* -la

# Copy the finder related scripts and executables to the /home directory
# on the target rootfs
echo "Copy writer to ${OUTDIR}/rootfs/home"
cp writer ${OUTDIR}/rootfs/home
echo "copy status:  $?"
echo "Copy sh files to ${OUTDIR}/rootfs/home"
cp *.sh ${OUTDIR}/rootfs/home
echo "copy status:  $?"
cd ../conf
cp *.txt ${OUTDIR}/rootfs/home
echo "Show listing of home:"
ls -la ${OUTDIR}/rootfs/home

cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
cd ..

echo "run Chown"
# Chown the root directory
cd ${OUTDIR}/rootfs
sudo chown -R root:root *
cd ..

# Create initramfs.cpio.gz
echo "Create cpio"
gzip -f initramfs.cpio
ls -la
