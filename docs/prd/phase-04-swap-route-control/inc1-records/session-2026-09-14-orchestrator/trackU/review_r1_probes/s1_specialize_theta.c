/* L1 re-derivation: can a theta reach `specialize` un-normalized? scanBody is
   claimed to reject every body containing a collected theta by EXACT POINTER.
   Here the callee body holds an undef-seeded theta and is called with a
   substitutable classical argument. */
#include "CQ.h"
__attribute__((noinline)) static bool helper(int k) {
    bool b;
    b = cq_theta(b, 0.5);
    return b && (k > 1);
}
int main(void) {
    bool r = helper(3);
    return cq_measure(r);
}
