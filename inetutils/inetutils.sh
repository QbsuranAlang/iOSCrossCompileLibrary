#!/bin/bash
#  Automatic build script for libicmp libgnu libinetutils libls libtelnet
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Qbsuran Alang 2015.01.18
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
LIBNAME="inetutils"
VERSION="1.9.2"
MINIOSVERSION="6.0"
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################

ARCHS="i386 x86_64 armv7 armv7s arm64"
LIBS="libicmp libgnu libinetutils libls libtelnet"

DEVELOPER=`xcode-select -print-path`
#DEVELOPER="/Applications/Xcode.app/Contents/Developer"
SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`

REPOROOT=$(pwd)

OUTPUTDIR="${REPOROOT}/dependencies"
mkdir -p ${OUTPUTDIR}/iPhoneOS/include

BUILDDIR="${REPOROOT}/build"
INTERDIR="${BUILDDIR}/built"
mkdir -p $BUILDDIR
mkdir -p $INTERDIR

SRCDIR="${BUILDDIR}/src"
mkdir -p $SRCDIR

set -e
if [ ! -e "${SRCDIR}/${LIBNAME}-${VERSION}.tar.gz" ]; then
cd ${SRCDIR}
echo "Downloading ${LIBNAME}-${VERSION}.tar.gz"
curl -O http://ftp.gnu.org/gnu/inetutils/${LIBNAME}-${VERSION}.tar.xz
fi
echo "Using ${LIBNAME}-${VERSION}.tar.gz"
tar zxf ${SRCDIR}/${LIBNAME}-${VERSION}.tar.xz -C ${SRCDIR}
cd "${SRCDIR}/${LIBNAME}-${VERSION}"
set +e

#copy some include needed
DIRS="net netinet netinet6 sys arpa"
for DIR in ${DIRS}
do
mkdir -p ${OUTPUTDIR}/iPhoneOS/include/${DIR}
cp -r ${DEVELOPER}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${SDKVERSION}.sdk/usr/include/${DIR}/ ${OUTPUTDIR}/iPhoneOS/include/${DIR}/
cp -r -n /usr/include/${DIR}/ ${OUTPUTDIR}/iPhoneOS/include/${DIR}/
done
cp ${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk/usr/include/crt_externs.h ${OUTPUTDIR}/iPhoneOS/include/crt_externs.h

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

./configure ${EXTRA_CONFIG} \
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
--prefix="${INTERDIR}/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" \
CC="${CCACHE}${DEVELOPER}/usr/bin/gcc" \
LDFLAGS="$LDFLAGS -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION} ${EXTRA_LDFLAGS}" \
CFLAGS="$CFLAGS -g -O0 -D__APPLE_USE_RFC_3542 -arch ${ARCH} -fPIE -miphoneos-version-min=${MINIOSVERSION} ${EXTRA_CFLAGS} -I${OUTPUTDIR}/${PLATFORM}/include -isysroot ${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDKVERSION}.sdk"

make -j2

#copy output lib
for LIB in ${LIBS}
do
mkdir -p ${OUTPUTDIR}/${LIB}/${ARCH}/lib
if [ "${LIB}" == "libgnu" ]; then
cp ${SRCDIR}/${LIBNAME}-${VERSION}/lib/${LIB}.a ${OUTPUTDIR}/${LIB}/${ARCH}/lib/${LIB}.a
else
cp ${SRCDIR}/${LIBNAME}-${VERSION}/${LIB}/${LIB}.a ${OUTPUTDIR}/${LIB}/${ARCH}/lib/${LIB}.a
fi
done

make clean
done

########################################

echo "Build library..."

mkdir -p ${REPOROOT}/lib
for LIB in ${LIBS}
do
LIPOCMD=" -create "
for ARCH in ${ARCHS}
do
INPUT_ARCH_LIB="${OUTPUTDIR}/${LIB}/${ARCH}/lib/${LIB}.a"
LIPOCMD="${LIPOCMD} -arch ${ARCH} ${INPUT_ARCH_LIB} "
done
LIPOCMD="${LIPOCMD} -output ${REPOROOT}/lib/${LIB}.a"
lipo $LIPOCMD
done

echo "Building done."
if [ "$1" == "reserve" ]; then
echo "Reserve build file."
else
echo "Cleaning up..."
rm -fr ${BUILDDIR}
rm -rf ${OUTPUTDIR}
fi
echo "Done."
