/* slice_control_byref_frexp_caller.c — bd 0vvq (Increment 1) e2e smoke: an untainted
   control-merge %out feeding an ONWARD by-ref libm call (frexp), driven through the
   full clang -O1 -> opt cq-lowering -> link -> run pipeline. The ONLY layer that
   LINKS, so the only proof the re-run g387 markers resolve + signature-match against
   libcq_runtime (the cq_template_frexp_f64 / cq_template_frexpexp_f64_to_i32 producers
   + their _inv twins), Rule 2/16.

   SOURCE INTENT (0vvq unfreeze — the by-ref frozen-plan case dugh over-declined):
       q : tainted quantum condition handle
       int y = 5;  if (q>3) y = ext_f(7);     // 6.5 classical-call arm -> %out (i32)
       m = frexp((double)y, &e);              // by-ref math on the merged register
       measure(m); measure(e); measure(y);    // both frexp outputs are quantum producers

   The merge is data-untainted (ext_f(7) classical + constant 5), so the FIRST
   propagation classified the frexp classical and `lowerByRefMath` (step 2) left it
   RAW; dugh re-taints %out in round 2 but g387 had already run -> the frozen-plan
   over-decline. 0vvq Inc 1 RE-RUNS `lowerByRefMath` inside repropagateControlMerges,
   after the diamond is flattened, so the frexp lowers to the @cq_byref_* markers
   (mantissa m + exponent e), both reversible functions of %out.

   The `cq_measure(y)` is load-bearing: it keeps the merge an i32 register. Without an
   integer use of `y`, clang -O1 SINKS the `(double)y` cast into the arm, turning the
   merge into an fp phi (an angle, a DIFFERENT declined case). Measuring `y` and
   `e = frexpexp(y)` is NOT no-cloning -- `e`/`m` are reversible FUNCTIONS of `%out`
   (entangled), so the three measurements are correlated, not independent copies.

   `ext_f` is DECLARED (not defined) here so opt sees a visible, un-inlined, pure body
   only after classical_call_under_control_lib.c is linked in (Rule 9). %out and the
   frexp producer rails are LEFT ALLOCATED (measured / benign leak, Rule 6). */
#include <math.h>
int ext_f(int a);

int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);          /* taint q -> condition handle */
    int y = 5;
    if (q > 3)                     /* tainted-condition diamond -> classical-call arm */
        y = ext_f(7);              /* pure classical call -> route-merged %out (i32) */
    int e;
    double m = frexp((double) y, &e);   /* by-ref math on the merged quantum value */
    double mm = cq_measure(m);          /* measure the mantissa (fp)          */
    int ei = cq_measure(e);             /* measure the exponent (i32)         */
    int yi = cq_measure(y);             /* measure y -> pins the i32 merge    */
    return (int) mm + ei + yi;
}

int main(void) { (void) slice(); return 0; }
