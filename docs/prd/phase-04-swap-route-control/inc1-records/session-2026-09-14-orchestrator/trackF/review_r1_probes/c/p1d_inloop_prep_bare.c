#include "CQ.h"
/* p1d — in-loop state prep, bare _Bool rail condition minted in-body, carried
   bool feeding the NEXT iteration's guard (so the carried phi is a phi-desc). */
int main(void) {
    bool q = 0;
    int s = 0;
    for (int i = 0; i < 3; i++) {
        bool b = 0;
        if (q) { b = cq_theta(b, 0.5); }
        q = b;
        s += i;
    }
    return s + cq_measure(q);
}
