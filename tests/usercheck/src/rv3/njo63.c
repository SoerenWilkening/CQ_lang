/* cq-njo63 (CR rule 16 signal table, CR 1356-1358): raise with no handler registered is the effect entry raise on both
   sides: logged, no host call (a real SIGTERM would end the C oracle's sample); its result is musl's, computed in the
   circuit (owner ruling 2026-11-12 cq-dbtpi: 0 for 0 <= sig <= 64, else -1).
   r: a classical raise of an invalid signal whose result the program reads (-1). */
#include <signal.h>
#include "CQ.h"
int f(int x0, double t) {
    int x = x0;
    int r = raise(x0 + 400);
    cq_theta(&x, t);
    if (x > 1)
        raise(SIGTERM);
    return cq_measure(x) + r;
}
