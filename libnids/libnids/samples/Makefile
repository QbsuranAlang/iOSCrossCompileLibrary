#
# Makefile for libnids samples.
#
# Dug Song <dugsong@monkey.org>

srcdir		= .


CC		= /Applications/Xcode.app/Contents/Developer/usr/bin/gcc
CFLAGS		=  -g -O0 -D__APPLE_USE_RFC_3542 -arch arm64 -fPIE -miphoneos-version-min=6.0  -I/Users/QbsuranAlang/Desktop/libnids/dependencies/iPhoneOS/include -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS8.3.sdk -D_BSD_SOURCE
LDFLAGS		=  -arch arm64 -fPIE -miphoneos-version-min=6.0 

PCAP_CFLAGS	= -I/Users/QbsuranAlang/Desktop/libnids/libpcap-1.6.2 -I/Users/QbsuranAlang/Desktop/libnids/libpcap-1.6.2/bpf
PCAPLIB		= -L/Users/QbsuranAlang/Desktop/libnids/libpcap-1.6.2 -lpcap

LNET_CFLAGS	= -I/Users/QbsuranAlang/Desktop/libnids/libnet-1.2-rc3/include -DHAVE_SOCKADDR_SA_LEN -DLIBNET_BSDISH_OS -DLIBNET_BSD_BYTE_SWAP
LNETLIB		= -lnet

LIBS_CFLAGS	= -I../src $(PCAP_CFLAGS) $(LNET_CFLAGS)
LIBS		= -L../src -lnids $(PCAPLIB) $(LNETLIB) 

.c.o:
	$(CC) -c $(CFLAGS) -I. $(LIBS_CFLAGS) $<

all: overflows printall sniff
static shared: all

overflows: overflows.o
	$(CC) -o $@ overflows.o $(LDFLAGS) $(LIBS)

printall: printall.o
	$(CC) -o $@ printall.o $(LDFLAGS) $(LIBS)

sniff: sniff.o
	$(CC) -o $@ sniff.o $(LDFLAGS) $(LIBS)

static shared install installshared:
	@true

clean:
	rm -f *.o *~ overflows printall sniff

# EOF
