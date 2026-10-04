/* slice_control_value_mixedops.c — e2e smoke for a value diamond whose chain
   spans FIVE DIFFERENT binary stems (`sub`/`and`/`or`/`shl`/`xor`/`mul`) rather
   than the add/mul/xor of slice_control_value_diamond.c. Subject of
   `e2e-value-mixedops-twin-identical`; its twin is
   slice_control_value_mixedops_twin.c.

   WHY A THIRD PAIR WITH DIFFERENT OPCODES. The hoist hands the chain to
   `lowerOps`, which is where the M-C in-place decision (`cqrt_addc`/`cqrt_xorc`)
   and the HL/LH operand-order choice live. add/mul/xor alone exercise only the
   commutative-HL and the two in-place-convertible stems; `sub`/`and`/`or`/`shl`
   are NOT in-place-convertible and `sub` is non-commutative, so this pair is the
   one that would catch a hoist that changed the operand order or the in-place
   disposition relative to the manual straight-line spelling. STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int p = 7;
    cq_theta(&q, 0.5);
    cq_theta(&p, 0.25);
    if (q > 5) {
        p = p - 3;
        p = p & 1023;
        p = p | 64;
        p = p << 2;
        p = p ^ 5;
        p = p * 3;
    }
    return cq_measure(p);
}
int main(void) { (void) slice(); return 0; }
