/* r1: THE RULE-8 PROBE. The carried handle with a POST-LOOP non-diagonal gate,
   spelled so the 4.4 data select's condition is a clean i1 rail (no `_Bool`
   array cell, so bd `r903`'s i8 wire never appears).  The filed tripwire
   `loop_carried_handle_reject_postloop_rotation.ll` dies at that wall; this
   spelling does not have it. */
#include "CQ.h"
__attribute__((noinline))
int run(void) {
    int a = 5;
    for (int i = 0; i < 3; ++i) {
        bool b = cq_theta((bool)0, 0.5);
        if (b) a -= 3;
    }
    a = cq_theta(a, -0.5);      /* S-dagger on the carried register */
    return cq_measure(a);
}
int main(void) { (void) run(); return 0; }
