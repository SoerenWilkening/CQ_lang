__attribute__((noinline)) static int slice(int n) {
    _Bool b = cq_theta((_Bool)0, 0.5); int q = cq_theta(0, 0.25); int s = 0;
    for (int i = 0; i < n; ++i) { { int t = (b ^ (q > 1)) ? i : 55; s += cq_measure(t); } }
    return cq_measure(b) + cq_measure(q) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
