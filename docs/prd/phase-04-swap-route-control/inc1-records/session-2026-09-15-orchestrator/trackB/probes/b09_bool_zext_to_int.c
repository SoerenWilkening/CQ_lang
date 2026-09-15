/* b09 — how does a TAINTED `zext i1 -> i32` lower today? The bank's i8 cell
   makes exactly this cast, and whether it mints a second rail decides whether
   the type rewrite may run after `lowerOps` (SCOPE_L1a §3(a)) or must run
   before it. */
#include "CQ.h"
int main(void) {
    bool b = 0;
    b = cq_theta(b, 0.5);
    int x = b;
    return cq_measure(x);
}
