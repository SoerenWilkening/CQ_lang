/* t20 — the angle select with the rail defined in a DIFFERENT block from the
   select (S6's positional `Cond->getParent() == BB` prong). */
int slice(int u) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (u > 0) { r = r + 1; }
    r = cq_theta(r, b ? 0.9 : 0.3);
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(3); return 0; }
