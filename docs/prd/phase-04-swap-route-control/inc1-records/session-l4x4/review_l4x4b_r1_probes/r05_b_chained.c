/* r05 — b is a CHAINED theta on b0's rail; both dead after the region. */
int slice(void) {
    _Bool b0 = 0; int r = 7;
    b0 = cq_theta(b0, 0.3);
    _Bool b = cq_theta(b0, 0.2);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
