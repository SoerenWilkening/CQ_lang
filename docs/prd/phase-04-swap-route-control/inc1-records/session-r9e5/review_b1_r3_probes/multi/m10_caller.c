/* m10 (flat, not in a loop) — the Rz-stem ANGLE SELECT's round-2 window in PLAIN C (two TUs):
   `if (b) cq_phi(A); else cq_phi(B);` which `clang -O1` folds to ONE `cq_phi`
   with a `select` on the ANGLE. Sibling BEFORE. */
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    int keep = cq_measure(y);
    bool x = (y != 0);
    bool b  = cq_theta(x, 0.25);
    bool b3 = cq_theta(x, 0.9);
    if (b) cq_phi(0.9); else cq_phi(0.3);
    return cq_measure(b3) + keep;
}
int main(void) { (void) slice(); return 0; }
