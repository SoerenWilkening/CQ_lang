/* At CQ type `double` the SEED and the ANGLE are the SAME LLVM type, so ONE
   `double undef` constant object lands in BOTH slots. The oracle declines with
   `cq literal integrity: undef/poison literal reaches two emitted gate operands`.
   z9t1 normalizes ONLY the seed -> ONE undef slot survives -> does the guard
   still fire, or does this become an ACCEPT emitting an undef ANGLE? */
#include "CQ.h"
int main(void) {
    double d;              /* one uninitialized object, read twice */
    d = cq_theta(d, d);
    return (int)cq_measure(d);
}
