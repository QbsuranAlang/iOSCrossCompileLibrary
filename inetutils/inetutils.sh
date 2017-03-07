#!/bin/bash
#  Automatic build script for libicmp
#  for iPhoneOS and iPhoneSimulator
#
LIBNAME="inetutils"
VERSION="1.9.4"
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
mkdir -p ${BUILDDIR}
mkdir -p ${INTERDIR}

SRCDIR="${BUILDDIR}/src"
mkdir -p ${SRCDIR}

LOG=${REPOROOT}/log.txt

# download or use existed
set -e
if [ ! -e "${SRCDIR}/${LIBNAME}-${VERSION}.tar.gz" ]; then
cd ${SRCDIR}
echo "Downloading ${LIBNAME}-${VERSION}.tar.gz"
/usr/bin/curl -L -O http://ftp.gnu.org/gnu/inetutils/${LIBNAME}-${VERSION}.tar.gz >/dev/null
fi
echo "Using ${LIBNAME}-${VERSION}.tar.gz"
tar zxf ${SRCDIR}/${LIBNAME}-${VERSION}.tar.gz -C ${SRCDIR} >> ${LOG} 2>&1
cd "${SRCDIR}/${LIBNAME}-${VERSION}"
set +e

# copy some header is needed for iPhoneOS platform
DIRS="net netinet netinet6 sys arpa"
for DIR in ${DIRS} ;do
mkdir -p ${DEPSDIR}/iPhoneOS/include/${DIR}
cp -r ${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk/usr/include/${DIR}/ ${DEPSDIR}/iPhoneOS/include/${DIR}/
cp -r -n /usr/include/${DIR}/ ${DEPSDIR}/iPhoneOS/include/${DIR}/
done
cp ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk/usr/include/crt_externs.h ${DEPSDIR}/iPhoneOS/include/crt_externs.h

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
    --disable-servers \
    --disable-hostname --disable-ifconfig \
    --disable-logger --disable-ping \
    --disable-ping6 --disable-rcp \
    --disable-rexec --disable-rlogin \
    --disable-rsh --disable-talk \
    --disable-telnet --disable-tftp \
    --disable-traceroute --disable-whois \
    --disable-ftpd --disable-inetd \
    --disable-rexecd --disable-rlogind \
    --disable-rshd --disable-syslogd \
    --disable-talkd --disable-telnetd \
    --disable-tftpd --disable-uucpd \
    --disable-dnsdomainname --disable-ftp \
    ${EXTRA_CONFIG} \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    CC="${DEVELOPER}/usr/bin/gcc" \
    LDFLAGS="$LDFLAGS ${EXTRA_LDFLAGS} -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION}" \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} -g -O0 -D__APPLE_USE_RFC_3542 -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION} -I${DEPSDIR}/${PLATFORM}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \
    >> ${LOG} 2>&1

echo "Compiling ${PLATFORM}${SDKVERSION}-${ARCH}..."
make -j 4 >> ${LOG} 2>&1

echo $"Installing ${PLATFORM}${SDKVERSION}-${ARCH}..."
mkdir -p ${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include
cp ${SRCDIR}/${LIBNAME}-${VERSION}/libicmp/icmp.h ${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/include/

mkdir -p ${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib
cp ${SRCDIR}/${LIBNAME}-${VERSION}/libicmp/libicmp.a ${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/

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

echo "Archiving..."
TARGET=${REPOROOT}/target
mkdir -p ${TARGET}
mkdir -p ${TARGET}/lib
mkdir -p ${TARGET}/include

lipo_fat "lib/libicmp.a"
copy_file "include/icmp.h"

echo "Cleaning up..."
rm -rf ${BUILDDIR}
rm -rf ${DEPSDIR}
echo "Done."
echo "Built here: "${TARGET}
