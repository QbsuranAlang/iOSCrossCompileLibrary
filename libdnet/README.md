libdnet 1.12
=================
This libdnet version is mainly for ios to manipulate firewall.<br />
It contains the required header and cross compile script.<br />
This version's firewall API is for "pf" only.(OpenBSD, MAC OSX, iOS, etc...).<br />
I add three header, pfvar.h, radix.h, tree.h respectively in "libdnet/include".<br />
lib/libdnet.a is for arch: i386, x86_64, armv7, armv7s and arm64.<br />
Notice line 15-20
-----------------
File: src/fw-*.c are the same as fw-pf.c.<br />
```c
15    #define PRIVATE
16    #include <net/if.h>
17    #include <netinet/in.h>
18    #include "pfvar.h"
19    #define port xport.range.port
20    #define port_op xport.range.op
```
This is just for compile.
