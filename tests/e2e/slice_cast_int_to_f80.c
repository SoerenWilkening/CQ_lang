/* slice_cast_int_to_f80.c — bd 3c6m.5 e2e smoke (int -> long double): a tainted
   i32 widens to long double via `sitofp i32 to x86_fp80`, is scaled by a
   non-integer f80 literal (1.5L keeps clang -O1 from folding the cast away — the
   ×2.0 round-trip collapses to `shl`, Rule 9), and is measured as f80. LINK-proof
   that cq_template_sitofp_i32_to_f80 resolves + signature-matches the runtime
   (arity-1, i32 handle in/out — the f80 `long double` c_type never appears in a
   cast body). */
long double slice(void) {
    int qi = cq_theta(5, 0.5);          /* tainted i32                 */
    long double a = (long double)qi;    /* sitofp i32 -> f80           */
    long double b = a * 1.5L;           /* f80 arith (fmul_f80_hl)     */
    return cq_measure(b);               /* cqrt_measure_f80            */
}
int main(void) { (void) slice(); return 0; }
