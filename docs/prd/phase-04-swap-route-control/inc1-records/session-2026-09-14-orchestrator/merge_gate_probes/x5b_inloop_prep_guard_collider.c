/* X5-deep — in-loop prep with a classical guard on the seed value, the
   collider spelling F2 adjudicates. */
#ifndef CQ_K
#define CQ_K 2
#endif
int slice(int arg) {
    bool b = cq_theta((bool)0, 0.5);
    int s = 0;
    for (int k = 0; k < CQ_K; ++k) {
        int r = 7;
        if (b) r = cq_theta(7, 0.2);
        if (arg > 100) s += 1;
        s += cq_measure(r);
    }
    return s + cq_measure(b);
}
int main(void) { return slice(3); }
