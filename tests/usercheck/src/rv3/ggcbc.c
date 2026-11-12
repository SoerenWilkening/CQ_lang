/* cq-ggcbc (CR 1356-1358): a bodiless `__` callee is an effect entry on the lowered side, so the same stand-in on the C
   side. getchar_unlocked() with the macOS SDK is the macro __sgetc(stdin), whose refill is __srget: the C side called the
   host's, which read the checker's own stdin (the probe server hung). Here __srget is called directly, classically, on a
   null FILE (the host's would fault) and its result read: both sides read the stand-in's result; the mutant's is off by
   one. (The macro form puts the call under a predicate read from the host FILE, a quantum one on the lowered side: a
   deferred result, cq-dbtpi.) */
#include <stdio.h>
#include "CQ.h"
int __srget(FILE *);
int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    int c = __srget((FILE *)0);
    return cq_measure(x & 1) + (c & 0xff00);
}
