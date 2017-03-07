#!/bin/sh
#  Automatic build script for libssl and libcrypto 
#  for iPhoneOS and iPhoneSimulator
#
LIBNAME="openssl"
VERSION="1.1.0e"
MINIOSVERSION="7.0"

# variables
ARCHS="i386 x86_64 armv7 armv7s arm64"

DEVELOPER=`xcode-select -print-path`
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`

REPOROOT=$(pwd)

BUILDDIR="${REPOROOT}/build"
INTERDIR="${BUILDDIR}/built"
mkdir -p $BUILDDIR
mkdir -p $INTERDIR

SRCDIR="${BUILDDIR}/src"
mkdir -p $SRCDIR

LOG=${REPOROOT}/log.txt

# download or use existed
set -e
if [ ! -e "${SRCDIR}/${LIBNAME}-${VERSION}.tar.gz" ]; then
cd ${SRCDIR}
echo "Downloading ${LIBNAME}-${VERSION}.tar.gz"
/usr/bin/curl -L -O https://www.openssl.org/source/${LIBNAME}-${VERSION}.tar.gz >/dev/null
fi
echo "Using ${LIBNAME}-${VERSION}.tar.gz"
tar zxf ${SRCDIR}/${LIBNAME}-${VERSION}.tar.gz -C ${SRCDIR} >> ${LOG} 2>&1
cd "${SRCDIR}/${LIBNAME}-${VERSION}"
set +e

# start compiling
for ARCH in ${ARCHS} ;do
if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ] ; then
PLATFORM="iPhoneSimulator"
EXTRA_CONFIG="--host ${ARCH}-apple-darwin"
EXTRA_CFLAGS=""
EXTRA_LDFLAGS=""
else
PLATFORM="iPhoneOS"
EXTRA_CONFIG="--host arm-apple-darwin"
EXTRA_CFLAGS=""
EXTRA_LDFLAGS=""
sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
fi

mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/etc/openssl"
echo "Configuring ${PLATFORM}${SDKVERSION}-${ARCH}..."

# must be those name
export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
export BUILD_TOOLS="${DEVELOPER}"

export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"

if [[ "${VERSION}" =~ 1.0.0. ]]; then
    ./Configure BSD-generic32 \
    no-shared \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    --openssldir="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/etc/openssl" \
    >> ${LOG} 2>&1
elif [ "${ARCH}" == "x86_64" ]; then
    ./Configure darwin64-x86_64-cc \
    no-shared \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    --openssldir="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/etc/openssl" \
    >> ${LOG} 2>&1
else
    ./Configure iphoneos-cross \
    no-shared \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    --openssldir="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/etc/openssl" \
    >> ${LOG} 2>&1
fi

# add -isysroot to CC=
sed -ie "s!^CFLAG=!CFLAG=-I/usr/include -isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${MINIOSVERSION} !" "Makefile"

echo "Compiling ${PLATFORM}${SDKVERSION}-${ARCH}..."
make depend -j 4 >> ${LOG} 2>&1
make -j 4 >> ${LOG} 2>&1
echo $"Installing ${PLATFORM}${SDKVERSION}-${ARCH}..."
make -j 4 install >> ${LOG} 2>&1

make clean >/dev/null
done

echo "Compiling is done."

########################################
# archive files

function lipo_fat() {
    LIPO_ARGS=" -create "
    for ARCH in ${ARCHS} ;do

    if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
    PLATFORM="iPhoneSimulator"
    else
    PLATFORM="iPhoneOS"
    fi

    INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/$1"
    LIPO_ARGS="${LIPO_ARGS} -arch ${ARCH} ${INPUT_ARCH_LIB} "

    done

    LIPO_ARGS="${LIPO_ARGS} -output ${TARGET}/$1"
    lipo ${LIPO_ARGS}
}

function copy_file() {
    cp -R ${INTERDIR}/iPhoneOS${SDKVERSION}-arm64.sdk/$1 ${TARGET}/$1
}

function copy_dir() {
    cp -R ${INTERDIR}/iPhoneOS${SDKVERSION}-arm64.sdk/$1 ${TARGET}/
}

echo "Archiving..."
TARGET=${REPOROOT}/target
mkdir -p ${TARGET}
mkdir -p ${TARGET}/bin
mkdir -p ${TARGET}/etc
mkdir -p ${TARGET}/include
mkdir -p ${TARGET}/lib
mkdir -p ${TARGET}/share

lipo_fat "bin/openssl"
copy_dir "etc"
copy_dir "include"
lipo_fat "lib/libcrypto.a"
lipo_fat "lib/libssl.a"
copy_dir "share"

echo "Cleaning up..."
rm -rf ${BUILDDIR}
echo "Done."
echo "Built here: "${TARGET}
