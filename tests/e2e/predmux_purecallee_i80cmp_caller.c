/* predmux_purecallee_i80cmp_caller.c — bd 3c6m.14.1 e2e: the CQ translation
   unit, and the only layer that LINKS.

   WHAT THIS SLICE PROVES THAT NO .ll FIXTURE CAN. bd 3c6m.14.1 widened the
   pending-specialization pure-callee proof to admit an fp80 bit-pattern
   `icmp i80` (one ConstantInt operand ⇒ provably `_hl`). The consequence is
   that a tainted arm's call to such a callee is SPECULATED by PredMux's E4 and
   the callee is then specialized into a Phase-6 Bennett clone carrying
   `cq_template_icmp_eq_i80_hl` and its void `_unc` adjoint. Those two symbols,
   plus `cq_template_and_i80_hl(_unc)` and `cq_template_bitcast_f80_to_i80(_unc)`,
   must RESOLVE and SIGNATURE-MATCH against the generated template archive and
   the hand-written core ABI at link time (Rule 2, Rule 16). `opt -verify` and a
   green FileCheck say nothing about that; only this slice does.

   It is also the increment's real-body anchor. The 237 registered slices moved
   ZERO bytes under this change (measured against a pinned pre-change plugin) —
   `hypotl` is the only one that emits an i80 compare at all, and it emits it at
   top level, not through a callee — so the corpus has NO POWER here and its
   silence is not evidence. This slice is the shape that does land.

   SHAPE. A tainted-condition diamond with TWO merge phis (the W3 claim witness
   PredMux needs at top level), whose taken arm calls the outlined `leafl`:

       q = cq_theta(u0, 0.5)                 -- the sole taint source
       if (q < 0.5L) { r = leafl(q);         -- the SPECULATED pure call
                       z = r - 0.5L; z2 = r; }
       else          { z = q * 2.0L; z2 = q; }
       return cq_measure(z + z2)

   WHAT THE GOLDEN DOES AND DOES NOT WITNESS (stated because the trace runtime
   is trace-only and the honest scope of a golden has been mis-stated in this
   repo before):
     * IT DOES witness emission, linkage, signature match and gate ORDER — and,
       because bd 8txa moved the compare flag-strip onto the void out-first
       `_unc`, the trace does show that strip NAMING the rail the next line
       frees, inside the clone.
     * IT DOES NOT witness "freed at |0>". CLAUDE.md is explicit that no trace
       label can answer that at any ABI, which is the entire reason e2e stage 2b
       exists. The 6/6-verified free-pairing figure for this slice is
       `tools/free_pairing_check.py`'s, over the lowered IR — NOT the byte-diff's.
       An earlier draft of this header credited it to the golden; a Rule-13 lens
       caught that, and the overstatement mattered precisely because the bullet
       is presented as an honesty statement.
     * IT DOES NOT witness VALUE ROUTING. `cqrt_measure_*` returns 0 and no
       gate simulates, so the trace cannot tell a correct arm assignment from
       an inverted one. That obligation is discharged at the ir-pass level by
       control_predmux_accept_i80_cmp_purecallee.ll, whose CHECKs name both
       controlled-copy sources in order and were mutation-tested.
     * The `q < 0.5L` guard is not the taken path for any particular argument —
       the flatten makes both arms execute on every basis state, which is the
       point of the purity/totality proof.

   `noinline` on the driver is the standard slice discipline: whole-DAG
   uncompute is gated off in `main`, and at -O1 clang would otherwise inline the
   body so the uncompute never runs. */

long double leafl(long double);          /* defined in the lib TU, stays outlined */

__attribute__((noinline))
long double slice(long double u0)
{
    long double q = u0; cq_theta(&q, 0.5); /* alloc f80 + ry — the taint source */
    long double z, z2;

    if (q < 0.5L) {                      /* tainted condition -> PredMux claim */
        long double r = leafl(q);        /* the pure call, speculated by E4 */
        z  = r - 0.5L;
        z2 = r;
    } else {
        z  = q * 2.0L;
        z2 = q;
    }
    return cq_measure(z + z2);           /* -> cqrt_measure_f80 */
}

int main(void)
{
    (void) slice(1.25L);
    return 0;
}
