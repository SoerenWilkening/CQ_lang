/* RE-ATTACK 4 (Rule 13) — THE COMPOSITION OF THIS FIX WITH TRACK S′'s CONJUNCT-(3)
   WIDENING: the OUTER loop's own rail is an `icmp` USED AS DATA (the bd `7845`
   membership question), not a `BinaryOperator`, while the inner loop is marked.
   Before this fix the outer never reached conjunct (3) at all, so S′'s widening
   was unreachable through a nest. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int i = 1; i <= 2; ++i) {
        s += cq_measure(y > i);
        for (int j = 0; j < 2; ++j) {
            int u = cq_theta(6, 0.4);
            s += cq_measure((u >> j) & 1);
        }
    }
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
