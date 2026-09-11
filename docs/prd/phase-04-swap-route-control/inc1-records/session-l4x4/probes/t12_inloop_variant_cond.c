/* t12 — in-loop with a LOOP-VARIANT bool condition (the body rotates b too),
   so `b` is a HEADER PHI and NOT a rail leaf. */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    for (int i = 0; i < 3; i++) {
        if (b) { r = cq_theta(r, 0.9); }
        b = cq_theta(b, 0.1);
    }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
