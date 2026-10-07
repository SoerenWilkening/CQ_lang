/* spec_switch_mux_caller.c — CQ TU for the bd p3kd.7.1 golden: a tainted-scrutinee
   `switch` and a two-constant-arm integer select, each inside a source-injected
   classical helper lifted to a reversible clone (spec_switch_mux_lib.c).

   smux lifts to __cq_q_smux_1: the clone's PredMux flattens the switch into a
   three-select chain (one `cq_template_icmp_eq_i32_hl` flag per case; the
   `unreachable` default contributes nothing) and `lowerCloneSelect` lowers each
   select to two `cqrt_copy_i32_controlled` copies, the second inside a ¬flag
   `cqrt_x` bracket. cmux lifts to __cq_q_cmux_1 the same way, with both arms
   materialized to |7> and |9> rails (left allocated, Rule 6). Each clone
   Bennett-wraps: copy-out, the complete reverse, then the frees.

   The caller measures smux(b) + cmux(b); the whole-DAG spine then reverses the add
   and calls each clone's `_unc` twin, which recomputes the clone's forward stream,
   un-copies the result rail and reverses again.

   LINK PROVES: both clones and both `_unc` twins, cq_template_icmp_eq_i32_hl /
   icmp_sgt_i32_hl and their `_unc`s, cqrt_copy_i32_controlled, cqrt_x and the
   and/add/mul templates resolve and signature-match across llvm-link. The helpers
   are DECLARED here (Rule 9: opt sees the un-inlined bodies only after the lib
   links in). */

/* bd p3kd.7.8 (2026-10-07): the lifted clone now runs MAIN'S stage list, so its
   tainted select lowers through main's 4.4 merge (CondTreeEmit/SelectMergeEmit)
   and the Bennett wrap reverses it mechanically. Two trace changes, golden
   regenerated deliberately: the merge's trailing ¬flag `cqrt_x` (nothing reads
   the flag after the second copy) and its mirror at the start of the reverse are
   elided as a pair; where an arm is a constant zero, its materialized |0> rail
   is copied (a no-op) and now freed after the reverse. Every other gate is
   unchanged. The descriptions above are
   the pre-p3kd.7.8 stream. */

int smux(int x);
int cmux(int x);

int slice(void) {
    int b = 6;
    cq_theta(&b, 0.5);
    int r = smux(b) + cmux(b);
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
