int ext(int);
int slice(void) {
    int acc = 0; int s = 0;
    for (int i = 0; i < 3; ++i) {
        _Bool b = cq_theta((_Bool)(s & 1), 0.5);   /* origin in body, seed loop-carried */
        if (b) cq_phi(0.3);
        acc += cq_measure(b) + ext(i);
        s = acc;
    }
    return acc;
}
int main(void){ (void) slice(); return 0; }
