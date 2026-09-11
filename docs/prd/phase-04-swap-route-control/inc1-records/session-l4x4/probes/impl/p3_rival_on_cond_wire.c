/* p3 — the UNFOLDED rival of t6: an in-place Ry on the CONDITION's own wire,
   with the register kept live so -O1 cannot fold it to a state prep. R4 must
   decline `rotation arm on a condition wire`. */
int slice(int q0) {
    int q = cq_theta(q0, 0.2);
    _Bool b = (_Bool)(q & 1);
    b = cq_theta(b, 0.5);
    if (b) { b = cq_theta(b, 0.9); }
    return (int) cq_measure(b);
}
int main(void) { (void) slice(3); return 0; }
