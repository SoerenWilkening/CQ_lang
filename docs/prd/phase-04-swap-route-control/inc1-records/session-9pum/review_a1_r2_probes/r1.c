int ext(int);
int slice(void) {
    _Bool b = 0; b = cq_theta(b, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        if (b) cq_phi(0.3);
        acc += cq_measure(b) + ext(i);
    }
    return acc;
}
int main(void){ (void) slice(); return 0; }
