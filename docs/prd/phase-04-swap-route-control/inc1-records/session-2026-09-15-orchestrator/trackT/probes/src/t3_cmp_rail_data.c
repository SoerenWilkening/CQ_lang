/* Track T — bd `7845`'s residual, as a Track-T customer: the interior rail is an
   `icmp` used as DATA (no region anywhere), the register is re-rotated after the
   loop.  The s82e fence MISSES it (conjunct (3) scans BinaryOperator only), so on
   the ORACLE it ACCEPTS and LEAKS — a live P1.  The pairing must discharge it. */
#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    for (int k = 1; k <= 2; ++k)
        s += cq_measure((y >> k) == 1);
    y = cq_theta(y, 0.9);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
