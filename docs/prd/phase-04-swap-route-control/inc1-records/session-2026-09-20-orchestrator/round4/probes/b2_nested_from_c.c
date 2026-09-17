/* b2 — is the NESTED guarded shape (b1) reachable from plain C at -O1?  The inner
 * loop's zero-trip guard sits INSIDE the outer loop, so the promotion's
 * `cqrt_alloc` is minted once PER OUTER TRIP.  CLAUDE.md "Loop scope" lists
 * "nested loops" among what declines. */
#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc;
    int r = 0;
    for (int j = 0; j < 2; ++j) {
        int acc = 5;
        for (int i = 0; i < n; ++i) {
            bool t = 0;
            t = cq_theta(t, 0.5);
            if (t) acc = 1;
        }
        r += cq_measure(acc);
    }
    return r;
}
