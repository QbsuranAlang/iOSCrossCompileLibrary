#!/bin/bash
#  Automatic build script for libdnet
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Qbsuran Alang 2015.11.19
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#  origin script from: https://github.com/chrisballinger/openvpn-server-ios/blob/master/build-libpcap.sh
###########################################################################
#  Change values here													  #
#																		  #
LIBNAME="libnids"
VERSION="1.24"
OUTPUT_LIBS="libnids.a"
MINIOSVERSION="6.0"
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################

ARCHS="i386 x86_64 armv7 armv7s arm64"

DEVELOPER=`xcode-select -print-path`
#DEVELOPER="/Applications/Xcode.app/Contents/Developer"
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`

REPOROOT=$(pwd)

OUTPUTDIR="${REPOROOT}/dependencies"
mkdir -p ${OUTPUTDIR}/iPhoneOS/include
mkdir -p ${OUTPUTDIR}/lib

BUILDDIR="${REPOROOT}/build"
INTERDIR="${BUILDDIR}/built"
mkdir -p $BUILDDIR
mkdir -p $INTERDIR

set -e
echo "Using ${LIBNAME}-${VERSION}"
cd ${LIBNAME}
set +e

#copy some include needed
DIRS="netinet"
for DIR in ${DIRS}
do
mkdir -p ${OUTPUTDIR}/iPhoneOS/include/${DIR}
cp -r ${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk/usr/include/${DIR}/ ${OUTPUTDIR}/iPhoneOS/include/${DIR}/
cp -r -n ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk/usr/include/${DIR}/ ${OUTPUTDIR}/iPhoneOS/include/${DIR}/
done

CCACHE=`which ccache `
set -e # back to regular "bail out on error" mode

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

./configure --disable-shared ${EXTRA_CONFIG} \
--prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
--with-libpcap="${REPOROOT}/libpcap-1.6.2" \
--with-libnet="${REPOROOT}/libnet-1.2-rc3" \
CC="${CCACHE}${DEVELOPER}/usr/bin/gcc" \
LDFLAGS="$LDFLAGS -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION} ${EXTRA_LDFLAGS}" \
CFLAGS="$CFLAGS -g -O0 -D__APPLE_USE_RFC_3542 -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION} ${EXTRA_CFLAGS} -I${OUTPUTDIR}/${PLATFORM}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk"

make -j2
make install

make clean
done

########################################

echo "Build library..."

mkdir -p ${REPOROOT}/lib
LIPOCMD=" -create "
for ARCH in ${ARCHS}
do
if [ "${ARCH}" == "i386" ] || [ "${ARCH}" == "x86_64" ]; then
PLATFORM="iPhoneSimulator"
else
PLATFORM="iPhoneOS"
fi
INPUT_ARCH_LIB="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/lib/${OUTPUT_LIB}/${OUTPUT_LIBS}"
LIPOCMD="${LIPOCMD} -arch ${ARCH} ${INPUT_ARCH_LIB} "
done
LIPOCMD="${LIPOCMD} -output ${REPOROOT}/lib/${OUTPUT_LIBS}"

lipo $LIPOCMD

echo "Building done."
if [ "$1" == "reserve" ]; then
echo "Reserve build file."
else
echo "Cleaning up..."
rm -fr ${BUILDDIR}
rm -rf ${OUTPUTDIR}
#rm -rf ${REPOROOT}/${LIBNAME}
fi
echo "Done."
