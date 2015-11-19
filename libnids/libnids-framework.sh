#!/bin/bash
#  Automatic build script for dnet.framework
#
#  Created by Qbsuran Alang 2015.11.19
#
#  origin script from: https://github.com/x2on/OpenSSL-for-iPhone/blob/master/create-openssl-framework.sh
###########################################################################
#  Change values here													  #
#																		  #
LIBNAME="libnids"
OUTPUT_LIBS="libnids.a"
FWNAME="nids"
HEADER="nids.h"
COPYS="nids.h"
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################

if [ ! -e lib/${OUTPUT_LIBS} ]; then
echo "Please run ${LIBNAME}.sh first!"
exit
fi

INCLUDE_DIR="/usr/include"
if [ -e ${INCLUDE_DIR}/${HEADER} ]; then
INCLUDE_DIR=/usr/include
elif [ -e /usr/local/include/${HEADER} ]; then
INCLUDE_DIR=/usr/local/include
elif [ -e /opt/local/include/${HEADER} ]; then
INCLUDE_DIR=/opt/local/include
else
echo "Please install ${LIBNAME}"
exit 1
fi

echo "Creating $FWNAME.framework"
mkdir -p $FWNAME.framework/Headers
libtool -no_warning_for_no_symbols -static -o $FWNAME.framework/$FWNAME lib/${OUTPUT_LIBS}
for COPY in ${COPYS}
do
cp -r ${INCLUDE_DIR}/${COPY} $FWNAME.framework/Headers/
done
echo "Created $FWNAME.framework"
rm -rf ${BUILDDIR}
