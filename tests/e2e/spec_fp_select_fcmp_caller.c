/* spec_fp_select_fcmp_caller.c — CQ TU for the bd tkmn Inc-1 golden: an
   FCMP-CONDITIONED fp select (the openlibm bsdsrc/b_exp.c:171 `isfinite(x) ?
   HUGE : x` shape, inlined into tgamma) inside a source-injected classical helper
   lifted to a reversible clone.

   mhelper (spec_fp_select_fcmp_lib.c) returns `(w != 2.0) ? 2.5 : w` for
   `w = (double)n * (double)n` — the
   const/value-select-on-an-fcmp shape of b_exp.c:171, written fold-resistantly
   (see the lib TU header for why the literal isfinite test cannot be used here). The
   specializer lifts it into __cq_q_mhelper_1: the condition flag is minted by
   `cq_template_fcmp_une_f64_hl` — the fcmp family stem this increment made
   reachable from isLiftableFpSelect (isAdmissibleCloneSelect since bd p3kd.7.1)
   — the ConstantFP arm is materialized to a
   fresh `cqrt_alloc_f64(2.5)` |const> rail (LEAKED, Rule 6), the two
   `cqrt_copy_f64_controlled` copies are ¬flag `cqrt_x`-bracketed, and the Bennett
   wrap reverse-plays copies + flag and frees every tainted rail on |0>.

   SAFE with no angle fence: a clone body is provably ROTATION-FREE (scanBody
   rejects cq_theta/cq_phi as QuantumPrimitive), so the compared fp value has no
   rotation arg-1 angle slot to reach and kjd1's top-level stale-condition wire
   guard is vacuous here.

   LINK PROVES (the reason this slice exists — see the lib TU header):
   cq_template_fcmp_une_f64_hl and its `_unc` twin, cqrt_alloc_f64,
   cqrt_copy_f64_controlled, and cq_template_sitofp_i32_to_f64(+_unc) all resolve
   and signature-match. mhelper is DECLARED here (Rule 9 — opt sees the un-inlined
   body only after the lib links in). */

/* bd p3kd.7.8 (2026-10-07): the lifted clone now runs MAIN'S stage list, so its
   tainted select lowers through main's 4.4 merge (CondTreeEmit/SelectMergeEmit)
   and the Bennett wrap reverses it mechanically. Two trace changes, golden
   regenerated deliberately: the merge's trailing ¬flag `cqrt_x` (nothing reads
   the flag after the second copy) and its mirror at the start of the reverse are
   elided as a pair; where an arm is a constant zero, its materialized |0> rail
   is copied (a no-op) and now freed after the reverse. Every other gate is
   unchanged. The descriptions above are
   the pre-p3kd.7.8 stream. */

double mhelper(int n);

double slice(void) {
    int b = 3;
    cq_theta(&b, 0.5);
    double r = mhelper(b);
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
