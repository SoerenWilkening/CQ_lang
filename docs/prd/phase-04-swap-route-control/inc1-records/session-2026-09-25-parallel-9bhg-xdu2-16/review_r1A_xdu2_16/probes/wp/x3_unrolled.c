__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int a = 0;
    { if ((q > 1) & (r < 5)) a ^= 1; }
    { if ((q > 1) & (r < 5)) a ^= 1; }
    int s = cq_measure(a); r = cq_theta(r, 0.9); return s + cq_measure(q) + cq_measure(r);
}
int main(void) { volatile int k = 2; return slice(k); }
