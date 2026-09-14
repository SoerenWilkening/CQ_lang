/* X5-deep — the same back-edge carry, on the in-place controlled-Ry ARM
   branch of bd wx8g rather than the prep branch. */
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int q = cq_theta(0, 0.3);
    int s = 0;
    int carry = 0;
    for (int k = 0; k < CQ_K; ++k) {
        if (b) q = cq_theta(q, 0.25);
        carry = carry + 1;
        s += carry;
    }
    return s + cq_measure(q) + cq_measure(b);
}
int main(void) { return slice(); }
