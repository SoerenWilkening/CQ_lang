/* t1c — t1's COMPARE twin (int condition). The shipped drbq Inc-1 accept. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    if (q == 5) { r = cq_theta(r, 0.9); }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
