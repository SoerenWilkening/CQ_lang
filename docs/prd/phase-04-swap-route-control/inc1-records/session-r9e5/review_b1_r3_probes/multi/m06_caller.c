/* m06 — the KICKBACK consumer's round-2 window in PLAIN C (two TUs). The
   register-free `cq_phi` region is put inside a classically-bounded loop so the
   rail branch gets its own block (the `w1`/`e09` shape declines `control flow`
   because the branch sits in the previous region's merge block). The sibling is
   BEFORE the loop, on the same `%out`-derived wire. */
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b  = cq_theta(x, 0.25);
    bool b3 = cq_theta(x, 0.9);
    for (int i = 0; i < 3; i++) { if (b) cq_phi(0.7); }
    return cq_measure(b3) + keep;
}
int main(void) { (void) slice(); return 0; }
