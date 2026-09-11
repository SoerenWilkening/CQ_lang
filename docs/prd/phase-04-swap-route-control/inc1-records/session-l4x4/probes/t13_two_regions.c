/* t13 — TWO sequential regions on ONE rail: an Ry arm then a kickback. */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    if (b) { cq_phi(0.7); }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
