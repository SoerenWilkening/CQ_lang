#include "CQ.h"
/* cq-j2r0j (CR rules 19 and 27): a declared clone's result that the caller returns is kept, so it is
   copied into a fresh kept rail and the twin is called exactly once (lowered with -cq-roots naming
   ext_job). */
extern long ext_job(long);
long p_ret(long x0, double th) {
    long c = x0;
    cq_theta(&c, th);
    return ext_job(c);
}
