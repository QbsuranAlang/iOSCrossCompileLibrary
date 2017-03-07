#!/bin/bash
#  Automatic build script for libdnet
#  for iPhoneOS and iPhoneSimulator
#
LIBNAME="libdnet"
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

LOG=${REPOROOT}/log.txt

# download
set -e
if [ ! -e "${LIBNAME}" ]; then
echo "Downloading ${LIBNAME}"
git clone https://github.com/dugsong/libdnet ${LIBNAME}
fi
echo "Using ${LIBNAME} from github"
cd ${LIBNAME}
set +e

# copy some header is needed for iPhoneOS platform
DIRS="net netinet netinet6 sys"
for DIR in ${DIRS} ;do
mkdir -p ${DEPSDIR}/iPhoneOS/include/${DIR}
cp -r ${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk/usr/include/${DIR}/ ${DEPSDIR}/iPhoneOS/include/${DIR}/
cp -r -n ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk/usr/include/${DIR}/ ${DEPSDIR}/iPhoneOS/include/${DIR}/
done

# pf firewall dependency
# stupid way, but useful
cp ${REPOROOT}/pf-deps/include/*.h ${REPOROOT}/${LIBNAME}/include/
cp ${REPOROOT}/pf-deps/src/fw-pf.c ${REPOROOT}/${LIBNAME}/src/fw-ipchains.c
cp ${REPOROOT}/pf-deps/src/fw-pf.c ${REPOROOT}/${LIBNAME}/src/fw-ipf.c
cp ${REPOROOT}/pf-deps/src/fw-pf.c ${REPOROOT}/${LIBNAME}/src/fw-ipfw.c
cp ${REPOROOT}/pf-deps/src/fw-pf.c ${REPOROOT}/${LIBNAME}/src/fw-none.c
cp ${REPOROOT}/pf-deps/src/fw-pf.c ${REPOROOT}/${LIBNAME}/src/fw-pf.c
cp ${REPOROOT}/pf-deps/src/fw-pf.c ${REPOROOT}/${LIBNAME}/src/fw-pktfilter.c

for ARCH in ${ARCHS}
do
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

function copy_file() {
    cp -R ${INTERDIR}/iPhoneOS${SDKVERSION}-arm64.sdk/$1 ${TARGET}/$1
}

function copy_dir() {
    cp -R ${INTERDIR}/iPhoneOS${SDKVERSION}-arm64.sdk/$1 ${TARGET}/
}

echo "Archiving..."
TARGET=${REPOROOT}/target
mkdir -p ${TARGET}
mkdir -p ${TARGET}/sbin
mkdir -p ${TARGET}/lib
mkdir -p ${TARGET}/include
mkdir -p ${TARGET}/man

copy_dir "include"
lipo_fat "lib/libdnet.a"
copy_dir "man"
lipo_fat "sbin/dnet"

echo "Cleaning up..."
rm -rf ${BUILDDIR}
rm -rf ${DEPSDIR}
rm -rf ${REPOROOT}/${LIBNAME}
echo "Done."
echo "Built here: "${TARGET}
