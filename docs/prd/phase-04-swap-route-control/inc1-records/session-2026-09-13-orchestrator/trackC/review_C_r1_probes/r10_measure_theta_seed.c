/* r10 — item 2: the classical arg-0 seed of a source theta, also measured. */
#include "CQ.h"
int main(void) {
    int seed = 3;
    int q = cq_theta(seed, 0.5);
    return cq_measure(seed) + cq_measure(q);
}
