/* t18c — t18's COMPARE twin: a compound condition with an in-place Ry arm. */
int slice(void) {
    int q = 3;
    int q2 = 4;
    int r = 7;
    q = cq_theta(q, 0.5);
    q2 = cq_theta(q2, 0.2);
    r = cq_theta(r, 0.25);
    if (q > 5 && q2 > 3) { r = cq_theta(r, 0.9); }
    return cq_measure(q) + cq_measure(q2) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
