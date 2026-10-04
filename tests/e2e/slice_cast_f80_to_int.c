/* slice_cast_f80_to_int.c — bd 3c6m.5 e2e smoke (long double -> int): a tainted
   long double is scaled by a non-integer f80 literal then narrowed to int via
   `fptosi x86_fp80 to i32` (genuine f80 source => clang -O1 cannot fold the
   truncation away) and measured as i32. LINK-proof that
   cq_template_fptosi_f80_to_i32 resolves + signature-matches the runtime. */
int slice(void) {
    long double q = 2.5L; cq_theta(&q, 0.5); /* tainted f80                */
    long double s = q * 1.5L;            /* f80 arith (fmul_f80_hl)    */
    int i = (int)s;                      /* fptosi f80 -> i32          */
    return cq_measure(i);                /* cqrt_measure_i32           */
}
int main(void) { (void) slice(); return 0; }
