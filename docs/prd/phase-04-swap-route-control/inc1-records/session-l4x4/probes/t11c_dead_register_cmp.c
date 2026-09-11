/* t11c — t11's COMPARE twin: q never measured. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    if (q == 5) { r = cq_theta(r, 0.9); }
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
