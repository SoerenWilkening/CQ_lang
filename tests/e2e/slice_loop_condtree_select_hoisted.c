/* slice_loop_condtree_select_hoisted.c — bd `test_C_libtooling-xdu2.16`, the e2e
   half: a COMPOUND condition tree feeding a 4.4 DATA select INSIDE A ROLLED LOOP.

       for (i = 0; i < 3; ++i) { int t = ((q > 1) & (r < 5)) ? i : 55; ... }

   `q` and `r` are loop-invariant, so `clang -O1` LICM-hoists the WHOLE tree — both
   compares and the fused `and i1` — into the loop preheader, and if-converts the
   ternary into a `select` in the body. On the pre-change ORACLE
   (`438c77bf45c02e3e`, main 983f9361) this program DECLINED:
   `cq loop lowering: round-1 iteration-local marking falsified by round-2 taint`.
   At ROUND 1 the loop layer granted the body an iteration-local marking on the
   hoisted `and` as an invariant root (clause (ii-d)); the 4.4 emitter then
   consumed the tree and ERASED that node, and the post-fixpoint re-ask refused
   the NULLED root unconditionally. bd xdu2.16 re-derives the grant from scratch
   under FINAL taint instead (it must be TOTAL; here the body reads `q` and `r`,
   two root mints, through the emitter's in-body flag mints).

   THE INVARIANTS TO READ THE GOLDEN BY, per trip:
     * both leaf flags are minted FROM THE REGISTERS, in the body, every trip —
       the compare is evaluated once in the source but the rail is re-read per
       activation, which is right precisely because the hoist's precondition is
       loop-invariance (no gate touches `q`/`r` anywhere in this program);
     * the toffoli node lands on a fresh `|0>` ancilla, the two X-bracketed
       controlled copies write a FRESH `%out`, the toffoli is undone, the ancilla
       freed, each compare `_unc`'d and freed — every freed rail is back at `|0>`
       (stage 2b STRICT) and nothing of the condition survives the trip;
     * `h0`/`h1` (the user's `q`/`r`) are only ever template operands: never
       bracketed, never freed; each `%out` is the user's `t` and is measured.

   THE WITNESS: `e2e-loop-condtree-select-hoisted-twin-identical` — this golden is
   BYTE-IDENTICAL to the hand-unrolled twin's (`..._unrolled.c`, which the ORACLE
   already lowers). Identity says the rolled lowering emits the same gate sequence
   as three written-out copies; it does not by itself say either is the right
   unitary (owner ruling S3, 2026-09-17) — that argument is in the header above
   and in TRACK_XDU2_16.md. The lowered module is K-INDEPENDENT (measured: the
   same line count at `i < 3` and `i < 1000`, without `-g`). */
int slice(void) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    for (int i = 0; i < 3; ++i) {
        int t = ((q > 1) & (r < 5)) ? i : 55;
        s += cq_measure(t);
    }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { (void) slice(); return 0; }
