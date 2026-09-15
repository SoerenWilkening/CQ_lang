/* j_gzgs_m28_VACUOUS_merge.c — bd `test_C_libtooling-gzgs`.
   VERBATIM COPY of session-2026-09-14c/trackX/probes/fp_m28.c, kept here under
   a name that says what it is.

   ⚠ THIS PROGRAM'S FOURTH REGION IS THE IDENTITY ON ITS WHOLE REACHABLE
   SUPPORT, so it CANNOT witness the F x P composition's merge. Measured on the
   session ORACLE cq-opt 0e280fc62a91cec2 (trace: j_gzgs_m28.trace, 29 lines):

     line  4-5  cqrt_ry_i1(h1, 0.5); cqrt_ry_i1_controlled(h0, h1, -0.5)
                = the NEGATED-control prep. By additivity the arm is Ry(0.5) on
                  the h0=0 branch and Ry(0.5)Ry(-0.5) = I on the h0=1 branch,
                  so b1 is |0> wherever b0 = 1.
     line 19    cqrt_toffoli(h0, h1, h7)   -> h7 = b0 AND b1
     line 21/23 the two cqrt_copy_i32_controlled that ARE the merge

   Amplitude on |b0=1, b1=1> is EXACTLY ZERO, so h7 is 0 on every populated
   branch, line 21 never fires, line 23 always fires, and h8 = h3 identically.
   The merge the composition NEWLY ENABLES cannot be told apart from several
   INCORRECT merges by anything this program can produce. That is this project's
   own headline lesson (every shipped Grover golden was the identity; the traces
   were self-consistent records of it).

   WHAT IT DOES WITNESS, and it is not nothing: that the composed accept
   PREDICATE fires (opt exit 0, no decline) and that the emitted stream is
   well-formed and stage-2b clean. Cite it for THAT and never for the unitary.
   The live twin is j_gzgs_x5b_LIVE_merge.c. */

#include "CQ.h"
#include <math.h>
int main(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;
    if (a >= 3){ b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    if (a >= 3){ b1 = cq_theta(b1, 0.5); }
    if (b1 && b0) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
