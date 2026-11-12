/* Owner ruling 2026-11-12 cq-dbtpi (ABI 1.11): fwide is a host-state result, its entry keeps the result rail; with a
   quantum mode field the call is deferred on every input (r |0>), and the program reads r on every input: no sample is
   compared against C, PASS (STRUCTURE ONLY) (never a PASS; a fault the lowered run alone shows is a FAIL). */
#include <stdio.h>
#include <wchar.h>
#include "CQ.h"
int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    int r = fwide(stdout, x);
    return cq_measure(r);
}
