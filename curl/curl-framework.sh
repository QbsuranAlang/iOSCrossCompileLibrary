#!/bin/bash
#  Automatic build script for json-c.framework
#
#  Created by Qbsuran Alang 2015.01.18
#
#  origin script from: https://github.com/x2on/OpenSSL-for-iPhone/blob/master/create-openssl-framework.sh
###########################################################################
#  Change values here													  #
#																		  #
LIBNAME="curl"
OUTPUT_LIBS="libcurl.a"
FWNAME="curl"
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################

if [ ! -e include-for-ios ]; then
echo "Missing include for ios"
exit 1
fi

echo "Creating $FWNAME.framework"
mkdir -p $FWNAME.framework/Headers
libtool -no_warning_for_no_symbols -static -o $FWNAME.framework/$FWNAME lib/${OUTPUT_LIBS}
cp -r include-for-ios/${LIBNAME}/ $FWNAME.framework/Headers/
echo "Created $FWNAME.framework"
