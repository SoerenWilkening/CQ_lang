__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    { { int t = ((q > 1) & (r < 5)) ? r : 0; s += cq_measure(t); } }
    { { int t = ((q > 1) & (r < 5)) ? r : 1; s += cq_measure(t); } }
    { { int t = ((q > 1) & (r < 5)) ? r : 2; s += cq_measure(t); } }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
