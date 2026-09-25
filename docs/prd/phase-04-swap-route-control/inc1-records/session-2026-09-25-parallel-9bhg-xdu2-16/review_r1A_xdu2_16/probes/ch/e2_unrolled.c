__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int w = cq_theta(2, 0.3); int s = 0;
    int y = (q > 2) ? r : 9;
    { int t = ((y > 4) | (w < 5)) ? w : 0; s += cq_measure(t); }
    { int t = ((y > 4) | (w < 5)) ? w : 1; s += cq_measure(t); }
    { int t = ((y > 4) | (w < 5)) ? w : 2; s += cq_measure(t); }
    return cq_measure(q) + cq_measure(r) + cq_measure(w) + s;
}
int main(void) { volatile int k = 3; return slice(k); }
