/* PART B, lens 5 at DEPTH 3 (the implementer measured only depth 2).  The
   hoisted `p = a*3` rail is minted outside ALL THREE loops and read in the
   INNERMOST body.  anchorForConsumer walks to the OUTERMOST loop not containing
   the mint => the discharge must be ONE `mul_i32_hl_unc` AFTER THE WHOLE NEST.
   An inner-exit placement repeats and would be refused by §2.9 (a leak);
   an over-outward placement cannot happen (there is nothing outside L1). */
int slice(void) {
    int a = 0;
    a = cq_theta(a, 0.5);
    int p = a * 3;
    int s = 0;
    for (int i = 0; i < 2; ++i)
        for (int j = 0; j < 2; ++j)
            for (int k = 0; k < 2; ++k)
                s += cq_measure((p >> (j + k)) & 1);
    return s + cq_measure(a);
}
int main(void) { return slice(); }
