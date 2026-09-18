// Z3 — the `loop_pairing_reject_round2_falsified.ll` shape written in C (no tainted
// control flow in the body, so the 2c condition-wire fence cannot speak first), with
// a RUNTIME trip bound so `-O1` emits a zero-trip GUARD, and a TRAILING non-diagonal
// gate on the register the hoisted rail copies.
//   forward `cq_template_mul_i32_hl(q,2)`  -> before the guard  (ALWAYS runs)
//   adjoint at `loopExitDischargePoint(L)` -> the loop's unique exit block
// If that exit block is a DEDICATED (LCSSA) one, the guard's false edge bypasses it
// and the n<=0 path runs the forward gate with NO adjoint: a live record of `q`
// standing at `cqrt_ry_i32(q, 0.9)`.  One path wrong, every other path right --
// invisible to a golden (one trip count per run) and to K-independence.
#include "CQ.h"
int slice(int u, int n) {
    int y = cq_theta(7, 0.3);
    int q = cq_theta(u, 0.5);
    int m2 = q * 2;
    int acc = 0;
    for (int k = 1; k < n; k++) {
        acc += cq_measure((y >> k) & m2);
    }
    q = cq_theta(q, 0.9);
    return acc + cq_measure(q) + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(4, argc); }
