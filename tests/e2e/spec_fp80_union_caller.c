/* spec_fp80_union_caller.c — bd vqlq e2e smoke: an fp80-union RMW inside a
   Phase-6 SPECIALIZED callee (see spec_fp80_union_lib.c for the mechanism).
   Driven through the full multi-TU pipeline (clang -O1 per TU -> llvm-link ->
   opt cq-lowering -> link -> run; the ONLY layer that LINKS, Rule 2/16).

   TRACE CONTRACT (analytically audited, bd vqlq): the clone computes the
   promoted chain on the borrowed theta handle h0 — sitofp -> bitcast f80->i80
   -> the offset-8 word extract (lshr/trunc/zext) -> the expsign rebuild
   (and/zext/and/or at i64) -> the i80 repack (and-keep/zext/shl/or) ->
   bitcast i80->f80 -> fmul -> fptosi — copies the i32 result onto a fresh
   |0> rail (cqrt_copy_i32), then reverse-plays EVERY op's `_unc` twin in
   exact reverse order (each with its original args still allocated), and
   frees every intermediate rail at proven-|0>. The borrowed theta rail h0 is
   read-only-preserved (never freed); the measured value rides the copy. */
int qpack(int a);

int slice(void) {
    int q = 3; cq_theta(&q, 0.5);
    int y = qpack(q);
    return cq_measure(y);
}

int main(void) { (void) slice(); return 0; }
