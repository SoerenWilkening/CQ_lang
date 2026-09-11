/* t9 — shape (9): `b` MEASURED before the branch. */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    int m = (int) cq_measure(b);
    if (b) { r = cq_theta(r, 0.9); }
    return m + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
