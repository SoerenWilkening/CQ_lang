/* cq-025xt: no cq_* call: the pass's identity, puts is the host's own (10 on macOS, musl's 0 is not the reference). */
#include <stdio.h>
int puts_host(int x) { return puts("h") * 256 + x; }
