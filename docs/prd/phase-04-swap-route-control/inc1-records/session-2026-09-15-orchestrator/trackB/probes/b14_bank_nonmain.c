/* b14 — b12 in a NON-`main` function.  `FreePoint` short-circuits to `Escaped`
   inside `main` (FreePoint.cpp:182-183), so the D1/D6 spine question — what
   disposition a STORED rail gets — is only askable outside it.  `noinline` is load-bearing: without it
   `-O1` inlines `kern` into `main` and the question disappears. */
#include "CQ.h"
__attribute__((noinline)) int kern(void) {
    bool b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
int main(void) { return kern(); }
