/* slice_bitcast_words.c — bd p119.7 e2e smoke (fp<->int bitcast round-trip): the
   EXTRACT_WORDS / INSERT_WORDS idiom that opens nearly every injected openlibm
   body. A tainted f64 is reinterpreted to i64 (`bitcast f64->i64`), a mantissa bit
   is flipped (`xor i64` — reversible, and NOT foldable to fabs/copysign so clang
   -O1 keeps the round-trip), reinterpreted back to f64 (`bitcast i64->f64`), and
   measured. LINK-proof that cq_template_bitcast_f64_to_i64 + _i64_to_f64 resolve +
   signature-match the runtime (arity-1, i32 handle in/out, Rule 15).

   Since M-C Increment 2c (bd test_C_libtooling-6uqc) the flip lowers IN PLACE to
   `cqrt_xorc_i64` — the int rail is dead after it, so no ancestor record of the
   bitcast rail is minted and the second bitcast reads the mutated rail directly.
   The two bitcast symbols this slice exists to link-prove are untouched. */
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);      /* tainted f64                       */
    unsigned long long bits;
    __builtin_memcpy(&bits, &q, 8);         /* EXTRACT_WORDS: bitcast f64 -> i64  */
    bits ^= 1ULL;                           /* flip mantissa LSB (cqrt_xorc_i64)  */
    double r;
    __builtin_memcpy(&r, &bits, 8);         /* INSERT_WORDS: bitcast i64 -> f64   */
    return cq_measure(r);                   /* cqrt_measure_f64                   */
}
int main(void) { (void) slice(); return 0; }
