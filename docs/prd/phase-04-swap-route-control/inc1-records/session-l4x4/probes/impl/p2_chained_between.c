/* p2 — a CHAINED theta between b's def and the branch: the branch names the
   stale `b` while the register has moved. Must DECLINE at rung (iii). */
int slice(int q0) {
    int q = cq_theta(q0, 0.2);
    _Bool t = (_Bool)(q & 1);
    int r = 7;
    _Bool b = cq_theta(t, 0.5);
    _Bool c = cq_theta(b, 0.9);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return (int) cq_measure(b) + (int) cq_measure(c) + cq_measure(r);
}
int main(void) { (void) slice(3); return 0; }
