/* r04 — b borrowed by a chain whose result is DEAD (no measure of z). */
int slice(void) {
    _Bool b = 0; int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    int z = (int) b + 1;
    (void) z;
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
