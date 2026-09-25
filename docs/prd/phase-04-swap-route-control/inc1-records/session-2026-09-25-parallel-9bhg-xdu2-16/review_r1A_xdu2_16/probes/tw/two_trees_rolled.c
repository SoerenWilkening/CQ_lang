__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    for (int i = 0; i < n; ++i) { { int t = ((q > 1) & (r < 5)) ? i : 55; int u = ((q < 3) | (r > 2)) ? 9 : i; s += cq_measure(t) + cq_measure(u); } }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
