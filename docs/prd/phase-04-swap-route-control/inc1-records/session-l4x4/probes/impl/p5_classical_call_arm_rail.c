/* p5 — ⚠ HEADER CORRECTED BY THE ROUND-1 RULE-13 REVIEW (finding F-4). THIS
   PROBE DOES NOT MEASURE WHAT ITS FIRST HEADER CLAIMED.

   The original header read: "the 6.5 CLASSICAL-CALL arm on a bare-rail
   condition (bd 54ur, 1b-B.2a). Must keep declining: `classifyClassicalCallArm`'s
   own `isa<CmpInst>` early return hands it to `classifyArms`, whose §2.6
   partition refuses it."  IT ACCEPTS — on this tree AND on `main` 0c7380c.

   MEASURED (`clang -O1`, this source): the stage-1 IR has **0 `br i1` and 2
   `select i1`**. `-O1` inlines and folds the `noinline const` callee's whole arm
   into a `select i32`, so there is NO control region and
   `classifyClassicalCallArm` is never reached at all: the program is handled by
   bd `r9e5`'s 1b-B.1 RAIL DATA-SELECT with `CopyRailRoot`, shipped before this
   increment, and emits
       cqrt_alloc_i1 ; cqrt_cnot ; 2x cqrt_copy_i32_controlled ;
       cqrt_x ; cqrt_cnot ; cqrt_free
   — the ancilla-copy stream, not a 6.5 arm and not a decline.

   SO IT MEASURES NOTHING ABOUT §2.6's CLASSICAL-CALL ROW, in either direction,
   and IMPL §1 must not cite it for that row. What DOES fence that class is
   `classifyClassicalCallArm`'s own `isa<CmpInst>` early return (unchanged by
   l4x4.b, verified by reading) plus `declineRailClass()` at `classifyArms`'
   accept sites — and there is NO DEDICATED FIXTURE for the row, because the
   class is not reachable from plain C at `-O1`. That gap is stated in
   `IMPL_l4x4b.md` §1 rather than papered over: a probe that measures a
   different lowering is worse than no probe, because it reads like coverage.

   KEPT RATHER THAN DELETED, with the measurement, because the fact it actually
   establishes is worth having: **the plain-C spelling of "a pure classical call
   in the arm of a bare-`_Bool` `if`" is already compiled, by r9e5.** bd `54ur`
   (1b-B.2a) therefore needs a spelling `-O1` does NOT fold — which is the first
   thing its implementer must measure. */
__attribute__((noinline, const)) static int pure_f(int a) { return a + 100; }
int slice(void) {
    _Bool b = 0;
    int y = 5;
    b = cq_theta(b, 0.5);
    if (b) y = pure_f(7);
    return (int) cq_measure(b) + cq_measure(y);
}
int main(void) { (void) slice(); return 0; }
