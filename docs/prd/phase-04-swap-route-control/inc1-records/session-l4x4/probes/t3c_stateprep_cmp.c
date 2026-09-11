/* t3c — t3's COMPARE twin. drbq Inc 4's shipped accept shape. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    if (q == 5) { r = cq_theta(7, 0.9); }
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
