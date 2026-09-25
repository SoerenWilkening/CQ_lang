__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int s = 0;
    int p = q * q;
    for (int i = 0; i < n; ++i) { int t = (p > 4) ? i : 55; s += cq_measure(t); }
    return cq_measure(q) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
