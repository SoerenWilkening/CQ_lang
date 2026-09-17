/* bd `tu9q` P2, ROUND-2 LENS 5, third attempt: a nest with NO tainted control flow
   at all, so it is not claimed by the loop layer's nested-loop refusal and the
   interior partition actually runs. The hoisted `p = a*3` rail is minted outside
   BOTH loops and read in the INNERMOST body.

   THE PROPERTY UNDER ATTACK: `anchorForConsumer` walks OUTWARD to the OUTERMOST
   loop not containing the mint. If it took the INNERMOST instead, the discharge
   would land at the inner exit — a point that repeats once per OUTER trip against
   a mint that ran once — and §2.9's `blockCanRepeat(At->getParent())` would refuse
   it, turning the right placement into a leak. So: ONE `cq_template_mul_i32_hl_unc`
   after the WHOLE nest is the pass; a leak (zero) is the fail. */
int slice(void) {
    int a = 0;
    a = cq_theta(a, 0.5);
    int p = a * 3;
    int s = 0;
    for (int i = 0; i < 2; ++i)
        for (int j = 0; j < 2; ++j)
            s += cq_measure((p >> j) & 1);
    return s + cq_measure(a);
}
int main(void) { return slice(); }
