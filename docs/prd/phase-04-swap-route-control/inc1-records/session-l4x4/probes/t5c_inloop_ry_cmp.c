/* t5c — t5's COMPARE twin. Expected: CLAUDE.md row W (LICM hoists the
   invariant compare; P4 declines `condition predates a non-diagonal gate`). */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    for (int i = 0; i < 3; i++) {
        if (q == 5) { r = cq_theta(r, 0.9); }
    }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
