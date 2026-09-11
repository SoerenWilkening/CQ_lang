/* r01 — b DEAD after the region (never measured, never read). */
int slice(void) {
    _Bool b = 0; int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
