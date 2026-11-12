/* cq-njo63 (CR rule 16 signal table, CR 1356-1358): raise with no handler registered is the effect entry raise on both
   sides, §6's stand-in: logged, its result the stand-in's, no host call (a real SIGTERM would end the C oracle's sample).
   r: a classical raise of an invalid signal whose result the program reads (resolved at the call: the stand-in's). */
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
