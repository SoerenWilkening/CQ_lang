/* spec_fp_select_caller.c — CQ TU for the Phase 6 / issue kmdc golden: an fp
   two-arm select (fabs) INSIDE a source-injected int->int helper lifted to a
   reversible clone. Mirrors specialize_caller's quantum core (theta -> helper ->
   measure); mhelper (spec_fp_select_lib.c) uses fp only as internal scratch and
   returns i32 via ilogb. The specializer lifts it into __cq_q_mhelper_1, emits the
   select as an fp cqrt_copy_f64_controlled two-arm merge (copy_T, ¬flag cqrt_x
   bracket, copy_F, cqrt_x), and Bennett-wraps it. SAFE with no angle fence — a
   clone body is rotation-free (kmdc). mhelper is DECLARED here (Rule 9 — opt sees
   the un-inlined body only after spec_fp_select_lib.c links in). */

/* bd p3kd.7.8 (2026-10-07): the lifted clone now runs MAIN'S stage list, so its
   tainted select lowers through main's 4.4 merge (CondTreeEmit/SelectMergeEmit)
   and the Bennett wrap reverses it mechanically. Two trace changes, golden
   regenerated deliberately: the merge's trailing ¬flag `cqrt_x` (nothing reads
   the flag after the second copy) and its mirror at the start of the reverse are
   elided as a pair; where an arm is a constant zero, its materialized |0> rail
   is copied (a no-op) and now freed after the reverse. Every other gate is
   unchanged. The descriptions above are
   the pre-p3kd.7.8 stream. */

int mhelper(int n);

int slice(void) {
    int b = 3;
    cq_theta(&b, 0.5);
    int r = mhelper(b);
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
