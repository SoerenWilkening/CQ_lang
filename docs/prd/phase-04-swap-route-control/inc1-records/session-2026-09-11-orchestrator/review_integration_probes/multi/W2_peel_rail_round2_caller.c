int ext_f(int a);
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);
    _Bool b  = cq_theta((_Bool)0, 0.25);
    _Bool b3 = cq_theta((_Bool)0, 0.9);
    int a = 5;
    int c = 0;
    if (b) { a = 2; c = cq_theta(c, 0.4); }
    return cq_measure(a) + cq_measure(b3) + cq_measure(c);
}
int main(void) { (void) slice(); return 0; }
