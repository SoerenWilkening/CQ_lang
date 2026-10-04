/* slice_qq_hl_arith.c — Phase 3 e2e smoke: Q+Q and Q+C arithmetic across the
   HH / HL / LH operand shapes (PRD §7, §2.4) on the post-O1 opcode stream.

   The golden pins what `clang -O1` ACTUALLY emits, not the C operators
   (PRD §2.9 — "lower what -O1 emits"). Each line below notes the surviving
   opcode + shape the pass lowers:

     x * y    HH  -> cq_template_mul_i32(hx, hy)      commutative, QQ; operands
                                                      ordered by BirthOrder
     x - 3    HL  -> cq_template_add_i32_hl(hx, -3)   RECONCILIATION: -O1
                                                      canonicalizes `x - C` to
                                                      `add x, -C`, so `sub_hl`
                                                      is unreachable from C
                                                      source; `sub` survives
                                                      only as the _lh form below
     100 - x  LH  -> cq_template_sub_i32_lh(100, hx)  `C - x` stays sub; the
                                                      genuine non-commutative
                                                      literal-on-left shape
     5 << x   LH  -> cq_template_shl_i32_lh(5, hx)    literal-on-left bitwise

   cq_theta/cq_measure resolve from CQ.h, force-included by run_slice.sh
   (-include CQ.h -I include). */
int slice(void) {
    int x = 2;
    int y = 5;
    cq_theta(&x, 0.5);       /* taint x -> handle (alloc i32(2), ry_i32) */
    cq_theta(&y, 0.25);      /* taint y -> handle (alloc i32(5), ry_i32) */

    int hh  = x * y;         /* HH  mul    */
    int hl  = x - 3;         /* HL  add -3 (canonicalized) */
    int lhs = 100 - x;       /* LH  sub    */
    int lhl = 5 << x;        /* LH  shl    */

    return cq_measure(hh) + cq_measure(hl) + cq_measure(lhs) + cq_measure(lhl);
}
int main(void) { (void) slice(); return 0; }
