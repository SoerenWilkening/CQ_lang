/* slice_uncompute_interior_chained_theta.c — M-B Increment 5b (bd
   test_C_libtooling-6uqc). bd 6uqc's P4 end to end: the shape that at HEAD
   c36934a DECLINED, and the reason the whole record-family campaign exists.

       cq_theta(&a, 0.5);
       int f = sqrt(a + 3.0) <= 5.0;
       int m = cq_measure(f);
       cq_theta(&a, 0.5);
       return m + cq_measure(a);

   THREE COMPILERS, THREE ANSWERS, and the middle one is why this slice is worth
   its own golden:
     * before the M-A guard (d2828e3 and earlier) it ACCEPTED, opt rc=0: the
       second cqrt_ry fired with the sqrt/fadd/sitofp/fcmp records live and
       entangled with the wire. Verify-clean, free-pairing-clean, physically
       dephased -- a silent-miscompile-class accept.
     * with the M-A guard (b4e329b onward) it DECLINED loudly with
       "cq rotation lowering: non-diagonal gate over a live derived record".
       Correct, and a real capability loss: this is ordinary C.
     * now it LOWERS, because the records are gone before the gate rather than
       tolerated at it.

   WHAT THE GOLDEN WITNESSES. The whole LIFO reversal -- four _unc/free pairs --
   sits BETWEEN the zext that copies the flag out and the second cqrt_ry. Every
   _unc reads the PRE-Ry basis of h0, which is the basis its forward gate read
   (clause (d) of the record algebra); the Ry then fires on a wire carrying no
   undischarged record of itself. Read the ORDER, not the line count: a reversal
   emitted after the Ry would be exactly the unsoundness owner ruling 2026-08-27
   forbids ("a discharge scheduled AFTER a non-diagonal wire gate is itself
   unsound -- the _unc would read a post-Ry basis"), and the byte-diff is the only
   shipped gate that can see the difference between the two orders.

   h0 is still NEVER adjointed and NEVER freed: it is the BORROWED source wire,
   and the user measures it on the last line. Its absence from the reversal is a
   positive assertion.

   The straight-line half of the same chain, without the chained theta, is
   slice_uncompute_interior_chain.c; the region half (bd 6uqc's P0) is Increment
   6's customer and still leaks its sqrt rail behind the flag strip.

   noinline: the trace comes from a real callee rather than an inlined copy.
   The runtime is trace-only, so every gate fires unconditionally. */
#include <math.h>

__attribute__((noinline))
int slice(int a) {
    cq_theta(&a, 0.5);
    int f = sqrt(a + 3.0) <= 5.0;
    int m = cq_measure(f);
    cq_theta(&a, 0.5);
    return m + cq_measure(a);
}
int main(void) { (void) slice(1); return 0; }
