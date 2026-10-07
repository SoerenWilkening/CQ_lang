/* spec_fp_select_const_caller.c — CQ TU for the bd 20xt.3 golden: a CONST/CONST
   fp80 select (the atan2l -> inner atanl ±pi/2 overflow arm) INSIDE a
   source-injected int->long-double helper lifted to a reversible clone. Mirrors
   spec_fp_select_caller's quantum core (theta -> helper -> measure); mhelper
   (spec_fp_select_const_lib.c) returns `(n<0) ? -1.5L : 2.5L` — both arms
   ConstantFP. The specializer lifts it into __cq_q_mhelper_1, materializes each
   ConstantFP arm to a fresh `cqrt_alloc_f80(<const>)` |const> rail (leaked, Rule
   6), emits the two `cqrt_copy_f80_controlled` merge (copy_T, ¬flag cqrt_x
   bracket, copy_F, cqrt_x), copies the fp80 result out (`cqrt_copy_f80`), and
   Bennett-wraps it. SAFE with no angle fence — a clone body is rotation-free. LINK
   proves cqrt_alloc_f80 / cqrt_copy_f80_controlled / cqrt_copy_f80 /
   cq_template_icmp_slt_i32_hl(+_unc) all resolve and signature-match. mhelper is
   DECLARED here (Rule 9 — opt sees the un-inlined body only after the lib links
   in). */

/* bd p3kd.7.8 (2026-10-07): the lifted clone now runs MAIN'S stage list, so its
   tainted select lowers through main's 4.4 merge (CondTreeEmit/SelectMergeEmit)
   and the Bennett wrap reverses it mechanically. Two trace changes, golden
   regenerated deliberately: the merge's trailing ¬flag `cqrt_x` (nothing reads
   the flag after the second copy) and its mirror at the start of the reverse are
   elided as a pair; where an arm is a constant zero, its materialized |0> rail
   is copied (a no-op) and now freed after the reverse. Every other gate is
   unchanged. The descriptions above are
   the pre-p3kd.7.8 stream. */

long double mhelper(int n);

long double slice(void) {
    int b = 3;
    cq_theta(&b, 0.5);
    long double r = mhelper(b);
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
