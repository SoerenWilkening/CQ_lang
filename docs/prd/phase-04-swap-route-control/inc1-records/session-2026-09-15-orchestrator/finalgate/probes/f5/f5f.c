/* F-5 probe f: an UNALLOWED bank reader (D5 declines) in a module that ALSO has
   an E2 undef measure. Which diagnostic wins, and does anything go silent?
   `b0[0] + b0[1]` is an `add` reader -- not on the D5 allow-list. */
#include "CQ.h"
int slice(void) {
    bool b0[3];
    int u;
    int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    s += b0[0] + b0[1];
    s += cq_measure(u);
    return s;
}
int main(void) { (void) slice(); return 0; }
