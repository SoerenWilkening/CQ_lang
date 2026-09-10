/* m07 — CONTROL for m06: the SIBLING deleted, nothing else changed. Must ACCEPT
   on both binaries, byte-identical. */
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b  = cq_theta(x, 0.25);
    for (int i = 0; i < 3; i++) { if (b) cq_phi(0.7); }
    return cq_measure(b) + keep;
}
int main(void) { (void) slice(); return 0; }
