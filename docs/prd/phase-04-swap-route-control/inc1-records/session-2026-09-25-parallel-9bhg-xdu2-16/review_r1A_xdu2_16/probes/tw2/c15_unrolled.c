__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    { int c = (q > 1) & (r < 5); int t = c ? 0 : 55; int u = c ? 7 : 0; s += cq_measure(t) + cq_measure(u); }
    { int c = (q > 1) & (r < 5); int t = c ? 1 : 55; int u = c ? 7 : 1; s += cq_measure(t) + cq_measure(u); }
    { int c = (q > 1) & (r < 5); int t = c ? 2 : 55; int u = c ? 7 : 2; s += cq_measure(t) + cq_measure(u); }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
