/* Track beta P1 — conjunct (2) uses DOMINANCE, not reachability (IMPL_S §16.2).
   The loop sits under a classical `if`, so `L->getHeader()` does not dominate
   the post-loop rotation's block. `main` passes a NON-constant so the branch
   survives `-O1` in both the out-of-line body and the inlined copy. */
#include "CQ.h"
int slice(int c) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    if (c) {
        for (int k = 1; k <= 2; ++k)
            s += cq_measure((y >> k) & 1);
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(int argc, char **argv) { (void)argv; return slice(argc); }
