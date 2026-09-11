int ext_f(int a); int ext(int);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5; if (q > 5) y = ext_f(7);
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        int b = cq_theta(y, 0.25);
        int a = (b == 1) ? i : 5;
        acc += cq_measure(a) + cq_measure(b) + ext(i);
    }
    return acc;
}
int main(void){ (void) slice(); return 0; }
