__attribute__((noinline)) static int slice(int n) {
    double d = cq_theta(0.0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    for (int i = 0; i < n; ++i) { { int t = ((d > 0.5) | (r == 1)) ? i : 55; s += cq_measure(t); } }
    return (int)cq_measure(d) + cq_measure(r) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
