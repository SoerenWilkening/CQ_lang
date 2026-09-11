/* t21 — the Ry-stem angle select on an invariant rail INSIDE a loop (S7). */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    for (int i = 0; i < 3; i++) { r = cq_theta(r, b ? 0.9 : 0.3); }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
