/* t8c — t8's COMPARE twin. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    if (q == 5) { r = cq_theta(r, 0.9); }
    q = cq_theta(q, -0.5);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
