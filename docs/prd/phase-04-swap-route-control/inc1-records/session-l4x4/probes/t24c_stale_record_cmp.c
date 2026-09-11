/* t24c — t24's COMPARE twin (R6 declines). */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    int mark = r;
    if (q == 5) { r = cq_theta(r, 0.9); }
    return cq_measure(q) + cq_measure(r) + cq_measure(mark);
}
int main(void) { (void) slice(); return 0; }
