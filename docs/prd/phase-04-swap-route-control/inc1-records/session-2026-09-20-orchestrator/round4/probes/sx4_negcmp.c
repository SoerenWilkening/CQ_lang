/* sx4 — a NARROW SIGNED COMPARE against a NEGATIVE literal, inside the carried
 * loop.  This is the door where the missing `signext` changes an ANSWER and not
 * just a label: the callee reads 65533 where the source wrote -3, and
 * `65533 > 2` and `-3 > 2` are opposite. */
#include "CQ.h"
int main(void) {
    short a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        if (a > -3) {
            b0[i] = cq_theta(b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }
    return cq_measure(b0[0]) + (int)cq_measure(a);
}
