/* r34 — same, but the classical measure's result escapes the arm through the merge. */
#include "CQ.h"
int main(void) {
    int q = cq_theta(3, 0.5);
    int c = 9, a = 1;
    if (q == 3) { cq_phi(0.3); a = cq_measure(c); }
    return a + cq_measure(q);
}
