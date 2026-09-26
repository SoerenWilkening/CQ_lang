__attribute__((noinline, const)) int ext_f(int a) { return a * 3 + 1; }
__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(3, 0.5); int r = cq_theta(1, 0.5); int s = 0; int y = 4;
    if (q > 5) y = ext_f(7);
    for (int i = 0; i < n; ++i) { int t = ((r < 5) && (y == m)) ? i : 55; s += cq_measure(t); }
    return cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k, 22); }
