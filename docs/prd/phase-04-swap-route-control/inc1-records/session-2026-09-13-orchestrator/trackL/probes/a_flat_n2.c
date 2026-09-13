/* a_flat_n2.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(i) HAND-UNROLLED, constant indices, N=2. clang -O1 SROA-scalarises the array COMPLETELY (0 allocas, 0 stores measured) so the pass sees the FLAT scalar-bool file: decline `control flow` at the b[1] value arm — Track M/R's subject, byte-identical main to ../probes/vb.c above the measures.
   ⚠ RETIREMENT TRIGGER (L8): when Track M/R lands the N=2 flat cascade this ACCEPTS with their recorded stream; the array is invisible by then. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b[2] = {0};
    if (a >= 3) b[0] = cq_theta(b[0], 0.5);
    if (b[0]) a -= 3;
    if (a >= 3) b[1] = cq_theta(b[1], 0.5);
    if (b[1]) a -= 3;
    return cq_measure(a) + cq_measure(b[0]) + cq_measure(b[1]);
}
