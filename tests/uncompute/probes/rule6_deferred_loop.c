/* tests/uncompute probe (cq-8qs3j, CR rules 6, 14): a classically bounded loop (its classical exit j == m into abort, its
 * quantum exit on b) whose reverse is deferred reads b; s + b is computed after it and b is dead, so rule 6 would clean b
 * from s + b through the loop's exit s. The loop's reverse still needs b: the clean-up gives way and b keeps its role.
 * Was: 'uncompute: cyclic uncompute dependency through rule 6'. */
#include <stdlib.h>
#include "CQ.h"
int nob2(int b, int m) {
    cq_theta(&b, 1.0);
    int s = 0;
    for (int j = 0;; j++) {
        if ((b >> j) == 5)
            break;
        if (j == m)
            abort();
        s += j;
    }
    return cq_measure(s + b);
}
