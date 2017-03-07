#!/bin/bash
#  Automatic build script for libdnet
#  for iPhoneOS and iPhoneSimulator
#
LIBNAME="libnids"
VERSION="1.24"
MINIOSVERSION="7.0"

# variables
ARCHS="i386 x86_64 armv7 armv7s arm64"

DEVELOPER=`xcode-select -print-path`
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`

REPOROOT=$(pwd)

DEPSDIR="${REPOROOT}/dependencies"
mkdir -p ${DEPSDIR}

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
/usr/bin/curl -L -O https://downloads.sourceforge.net/project/libnids/libnids/${VERSION}/${LIBNAME}-${VERSION}.tar.gz >/dev/null
fi
echo "Using ${LIBNAME}-${VERSION}.tar.gz"
tar zxf ${SRCDIR}/${LIBNAME}-${VERSION}.tar.gz -C ${SRCDIR} >> ${LOG} 2>&1
cd "${SRCDIR}/${LIBNAME}-${VERSION}"
set +e

# copy some header is needed for iPhoneOS platform
DIRS="netinet"
for DIR in ${DIRS} ;do
mkdir -p ${DEPSDIR}/iPhoneOS/include/${DIR}
cp -r ${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk/usr/include/${DIR}/ ${DEPSDIR}/iPhoneOS/include/${DIR}/
cp -r -n ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk/usr/include/${DIR}/ ${DEPSDIR}/iPhoneOS/include/${DIR}/
done

# copy deps
function check_deps() {
    mkdir -p ${DEPSDIR}/$1
    set -e
    if [ ! -e "${REPOROOT}/../$1/target" ]; then
    echo "Please build $1 first."
    exit
    fi
    set +e
}

check_deps "libpcap"
check_deps "libnet"

cp ${REPOROOT}/../libpcap/target/lib/libpcap.a ${DEPSDIR}/libpcap/
cp -R ${REPOROOT}/../libpcap/target/include/* ${DEPSDIR}/libpcap/
cp -R ${REPOROOT}/../libnet/target/* ${DEPSDIR}/libnet/
cp ${REPOROOT}/../libnet/target/lib/libnet.a ${DEPSDIR}/libnet/
cp ${REPOROOT}/../libnet/target/bin/libnet-config ${DEPSDIR}/libnet/
cp -R ${REPOROOT}/../libnet/target/include/* ${DEPSDIR}/libnet/

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
fi

mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
echo "Configuring ${PLATFORM}${SDKVERSION}-${ARCH}..."
./configure \
    --disable-shared \
    ${EXTRA_CONFIG} \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    --with-libpcap="${DEPSDIR}/libpcap" \
    --with-libnet="${DEPSDIR}/libnet" \
    CC="${DEVELOPER}/usr/bin/gcc" \
    LDFLAGS="$LDFLAGS ${EXTRA_LDFLAGS} -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION}" \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} -g -O0 -D__APPLE_USE_RFC_3542 -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION} -I${DEPSDIR}/${PLATFORM}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \
    >> ${LOG} 2>&1

echo "Compiling ${PLATFORM}${SDKVERSION}-${ARCH}..."
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

function copy_dir() {
    cp -R ${INTERDIR}/iPhoneOS${SDKVERSION}-arm64.sdk/$1 ${TARGET}/
}

echo "Archiving..."
TARGET=${REPOROOT}/target
mkdir -p ${TARGET}
mkdir -p ${TARGET}/include
mkdir -p ${TARGET}/lib
mkdir -p ${TARGET}/man

copy_dir "include"
lipo_fat "lib/libnids.a"
copy_dir "man"

echo "Cleaning up..."
rm -rf ${BUILDDIR}
rm -rf ${DEPSDIR}
echo "Done."
echo "Built here: "${TARGET}
