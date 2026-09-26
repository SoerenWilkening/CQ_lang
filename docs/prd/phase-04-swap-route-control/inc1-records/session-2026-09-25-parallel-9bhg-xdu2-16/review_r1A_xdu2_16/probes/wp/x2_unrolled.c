__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int a = 0;
    { if (q > 1) a ^= 1; }
    { if (q > 1) a ^= 1; }
    int s = cq_measure(a); q = cq_theta(q, 0.9); return s + cq_measure(q);
}
int main(void) { volatile int k = 2; return slice(k); }
