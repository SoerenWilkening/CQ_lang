/* o1 — the owner's grover_oracle_uncompute.c SECOND REGION in isolation
   (BRIEF §4): a controlled STATE PREP of a `_Bool` under a NEGATED bare-rail
   condition. This is the shape bd `b6ap`'s multi-phi peel will hand to l4x4.b. */
int slice(void) {
    _Bool b0 = 0;
    _Bool b1 = 0;
    b0 = cq_theta(b0, 0.5);
    if (b0 == 0) { b1 = cq_theta(b1, 0.5); }
    return (int) cq_measure(b0) + (int) cq_measure(b1);
}
int main(void) { (void) slice(); return 0; }
