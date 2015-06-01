#!/bin/bash
#  Automatic build script for icmp.framework
#
#  Created by Qbsuran Alang 2015.01.18
#
#  origin script from: https://github.com/x2on/OpenSSL-for-iPhone/blob/master/create-openssl-framework.sh
###########################################################################
#  Change values here													  #
#																		  #
LIBNAME="inetutils"
FWNAME="libicmp"
VERSION="1.9.2"
LIB="libicmp"
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################

if [ ! -e lib/${LIB}.a ]; then
echo "Please run ${LIBNAME}.sh first!"
exit
fi

REPOROOT=$(pwd)
BUILDDIR="${REPOROOT}/build"
SRCDIR="${BUILDDIR}/src"
mkdir -p $BUILDDIR
mkdir -p $SRCDIR

set -e
if [ ! -e "${SRCDIR}/${LIBNAME}-${VERSION}.tar.xz" ]; then
cd ${SRCDIR}
echo "Downloading ${LIBNAME}-${VERSION}.tar.gz"
curl -O http://ftp.gnu.org/gnu/inetutils/${LIBNAME}-${VERSION}.tar.xz
fi
echo "Using ${LIBNAME}-${VERSION}.tar.gz"
tar zxf ${SRCDIR}/${LIBNAME}-${VERSION}.tar.xz -C ${SRCDIR}
cd ${REPOROOT}
set +e

echo "Creating $FWNAME.framework"
mkdir -p $FWNAME.framework/Headers

libtool -no_warning_for_no_symbols -static -o $FWNAME.framework/$FWNAME ${REPOROOT}/lib/${LIB}.a

if [ ${LIB} == "libgnu" ]; then
cp -r ${SRCDIR}/${LIBNAME}-${VERSION}/lib/*.h $FWNAME.framework/Headers/
else
cp ${SRCDIR}/${LIBNAME}-${VERSION}/${LIB}/*.h $FWNAME.framework/Headers/
fi
echo "Created $FWNAME.framework"
rm -rf ${BUILDDIR}
