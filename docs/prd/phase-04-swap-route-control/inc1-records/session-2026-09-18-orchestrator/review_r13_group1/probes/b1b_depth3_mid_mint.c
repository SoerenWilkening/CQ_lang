/* PART B — the `r1_triple_nest_mid_rail` seed SCOPE_T2 names: the rail is minted
   in the MIDDLE loop's body and read in the INNERMOST body.  anchorForConsumer's
   OUTERMOST-not-containing walk must stop at the INNER loop (the middle loop
   CONTAINS the mint), so the discharge must be once per MIDDLE trip, at the
   inner loop's exit.  A discharge after the whole nest would be ONE adjoint
   against K_mid forward gates — a wrong unitary. */
int slice(void) {
    int a = 0;
    a = cq_theta(a, 0.5);
    int s = 0;
    for (int i = 0; i < 2; ++i) {
        int p = a * (3 + i);
        for (int j = 0; j < 2; ++j)
            s += cq_measure((p >> j) & 1);
    }
    return s + cq_measure(a);
}
int main(void) { return slice(); }
