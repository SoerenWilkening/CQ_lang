__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    int p = q ^ 5;
    { int t = ((p > 4) & (r < 5)) ? 0 : 55; s += cq_measure(t); }
    { int t = ((p > 4) & (r < 5)) ? 1 : 55; s += cq_measure(t); }
    { int t = ((p > 4) & (r < 5)) ? 2 : 55; s += cq_measure(t); }
    return cq_measure(p) + cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k, k); }
