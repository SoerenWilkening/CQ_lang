/* tests/loops-cutoff probe (rulings Q8, Q9, 2026-11-11; CR rules 2, 14): trip j's copy of a body cq_measure measures the
   carried rail of trip j; on an input that does not reach trip j that rail holds the previous value (its carried select's
   condition reads 0 there), and that extra execution is no event of the input (its rail a kept rail).
   Regenerate me_carried.O1.ll:
   clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec me_carried.c -o me_carried.O1.ll */
#include "CQ.h"
unsigned measure_carried(unsigned x0, unsigned w0, double th, unsigned k) {
    unsigned x = x0, w = w0; cq_theta(&x, th); cq_theta(&w, th);
    unsigned v = x, m = 0;
    while (x > k) {
        m += cq_measure(v);     /* trip j measures v_j */
        v = w;                  /* next value unrelated to the previous one */
        x >>= 1;
    }
    return m;
}
