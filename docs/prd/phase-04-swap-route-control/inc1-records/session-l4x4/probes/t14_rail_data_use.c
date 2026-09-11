/* t14 — the rail is ALSO read as DATA after the region. */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { r = cq_theta(r, 0.9); }
    int s = r + (int) b;
    return (int) cq_measure(b) + cq_measure(s);
}
int main(void) { (void) slice(); return 0; }
