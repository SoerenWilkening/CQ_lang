/* t2c — t2's COMPARE twin. The shipped drbq Inc-2b accept. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    if (q == 5) { r = cq_theta(r, 0.9); } else { r = cq_theta(r, 0.3); }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
