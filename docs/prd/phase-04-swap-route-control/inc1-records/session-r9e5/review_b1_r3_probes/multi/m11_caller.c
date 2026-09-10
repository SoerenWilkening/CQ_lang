/* m11 — CONTROL for m10: the SIBLING deleted. */
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b  = cq_theta(x, 0.25);
    if (b) cq_phi(0.9); else cq_phi(0.3);
    return cq_measure(b) + keep;
}
int main(void) { (void) slice(); return 0; }
