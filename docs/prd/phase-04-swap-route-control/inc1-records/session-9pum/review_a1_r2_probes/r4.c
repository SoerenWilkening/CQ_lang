int ext(int);
int slice(void) {
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        int q = cq_theta(i, 0.5);
        if (q > 5) cq_phi(0.3);
        acc += cq_measure(q) + ext(i);
    }
    return acc;
}
int main(void){ (void) slice(); return 0; }
