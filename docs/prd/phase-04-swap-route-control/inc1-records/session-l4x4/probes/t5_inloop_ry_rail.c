/* t5 — shape (5): the Ry arm inside a classically-bounded loop, b LOOP-INVARIANT. */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    for (int i = 0; i < 3; i++) {
        if (b) { r = cq_theta(r, 0.9); }
    }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
