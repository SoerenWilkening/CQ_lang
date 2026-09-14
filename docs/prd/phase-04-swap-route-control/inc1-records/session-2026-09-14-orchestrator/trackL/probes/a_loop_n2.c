/* a_loop_n2.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   Q2(i) ARRAY spelling, N=2, ROLLED. DECLINE `cq taint escape: tainted value stored to memory` (TaintPropagation.cpp:526 kMsgStore) at the store of the theta result into b[i].
   ⚠ RETIREMENT TRIGGER (L8): when the bounded-alloca RAIL-ARRAY increment (L-1, filed this session) lands this ACCEPTS and the stream is one cqrt_alloc_i1 + one cqrt_ry_i1 per activation, the handle stored as an i32 into a rewritten [N x i32] alloca, every rail LEFT ALLOCATED. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b[2] = {0};
    for (int i = 0; i < 2; ++i) {
        if (a >= 3) b[i] = cq_theta(b[i], 0.5);
        if (b[i]) a -= 3;
    }
    int s = cq_measure(a);
    for (int i = 0; i < 2; ++i) s += cq_measure(b[i]);
    return s;
}
