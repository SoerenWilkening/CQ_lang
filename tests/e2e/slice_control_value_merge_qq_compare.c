/* slice_control_value_merge_qq_compare.c — e2e smoke for the ONE accept-class
   WIDENING that rides on bd test_C_libtooling-3qlq Inc 2 (Rule-13 round-1
   review finding F-V1-1; owner disposition OQ-22: KEEP and PIN).

   A Q+Q DATA COMPARE READ OFF A VALUE-ARM MERGE. Before Inc 2 this program
   DECLINED — measured on the pre-3qlq oracle (52d7764):
       error: … no template for opcode 'icmp i1' in tainted context
   because the retired `emitValueRegion` recorded no `taint.HandleWidth` entry
   for the merged register, and `CompareLowering::rewriteCompare`'s Q+Q path
   needs a RECORDED logical width (it never falls back to the SSA type of the
   laundered i32 handle). Inc 2 routes the value diamond through
   `emitSelectRegion`, which records that width (bd p119.6), so the consumer
   now resolves. NOTHING about the merge gates changed: the stream below is the
   4.4 controlled-XOR copy merge's own, identical to
   slice_control_value_diamond's, plus the compare the oracle could not lower.

   WHY THIS IS THE SLICE AND NOT ONLY A FIXTURE. e2e is the only layer that
   LINKS, so it is the only proof that `cq_template_icmp_eq_i32` and its `_unc`
   twin resolve and signature-match against the shipped runtime when reached
   from a value-arm merge (Rule 2/16). The width axis (i8/i16/i64 casts and
   compares) is pinned at the IR level by
   control_swap_value_accept_{i8_merge_cast,i64_merge_cast,qq_compare_*}.ll.

   NO TWIN GATE, deliberately: the pre-hoisted select twin of this program is a
   different accept path (`SelectClassify`'s own front door) and its disposition
   is not what this slice is about — the claim here is that the SYMBOLS LINK.
   The byte-identity witness for the merge itself is the diamond/ifelse/mixedops
   trio. Six-op chain so `-O1` keeps a real br-diamond (a short arm folds to a
   tainted select — see slice_control_value_diamond.c). STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int p = 7;
    int r = 2;
    q = cq_theta(q, 0.5);          /* condition register                        */
    p = cq_theta(p, 0.25);         /* value register (the merge base)           */
    r = cq_theta(r, 0.1);          /* the compare's OTHER quantum operand       */
    if (q > 5) {
        p = p + 3;
        p = p * 5;
        p = p ^ 9;
        p = p + 1;
        p = p * 7;
        p = p ^ 2;
    }
    int e = (p == r);              /* Q+Q compare ON the merged register        */
    return cq_measure(e);
}
int main(void) { (void) slice(); return 0; }
