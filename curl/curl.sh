#!/bin/bash
#  Automatic build script for curl and libcurl
#  for iPhoneOS and iPhoneSimulator
#
LIBNAME="curl"
VERSION="7.53.1"
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
/usr/bin/curl -L -O http://curl.haxx.se/download/${LIBNAME}-${VERSION}.tar.gz >/dev/null
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
fi

mkdir -p "${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
echo "Configuring ${PLATFORM}${SDKVERSION}-${ARCH}..."
./configure \
    --disable-shared \
    --enable-static \
    --enable-threaded-resolver \
    --with-darwinssl \
    ${EXTRA_CONFIG} \
    --prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
    CC="${DEVELOPER}/usr/bin/gcc" \
    LDFLAGS="$LDFLAGS ${EXTRA_LDFLAGS} -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION} " \
    CFLAGS="$CFLAGS ${EXTRA_CFLAGS} -g -O0 -D__APPLE_USE_RFC_3542 -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION} -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk" \
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
mkdir -p ${TARGET}/include
mkdir -p ${TARGET}/lib
mkdir -p ${TARGET}/share

lipo_fat "bin/curl"
cp -R ${REPOROOT}/include-for-ios/curl ${TARGET}/include/
lipo_fat "lib/libcurl.a"
copy_dir "share"

echo "Cleaning up..."
rm -rf ${BUILDDIR}
rm -rf ${DEPSDIR}
echo "Done."
echo "Built here: "${TARGET}
