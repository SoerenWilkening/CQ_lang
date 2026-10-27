/* Swap test: a control c in superposition, a controlled swap of two QUANTUM registers a and b, then the control is
 * un-rotated and measured. P(c = 0) = (1 + |<a|b>|^2) / 2. a and b are measured afterwards so the swap is live. Rule 6: the swap is a bijection on (a, b), so no record of
 * the pre-swap values may survive into the second rotation of c. */
int swap_test(int a0, double ta, int b0, double tb) {
    int a = a0, b = b0;
    bool c = 0;
    cq_theta(&a, ta);
    cq_theta(&b, tb);
    cq_theta(&c, 1.5707963267948966);
    if (c) { int t = a; a = b; b = t; }
    cq_theta(&c, -1.5707963267948966);
    return cq_measure(c) | (cq_measure(a) << 1) | (cq_measure(b) << 8);
}
