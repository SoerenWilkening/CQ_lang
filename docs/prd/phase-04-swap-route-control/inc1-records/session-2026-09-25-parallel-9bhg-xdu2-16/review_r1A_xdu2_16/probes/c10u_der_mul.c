__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int r = cq_theta(1, 0.5); int s = 0;
    int p = q * q;
    { int t = ((p > 4) & (r < 5)) ? 0 : 55; s += cq_measure(t); }
    { int t = ((p > 4) & (r < 5)) ? 1 : 55; s += cq_measure(t); }
    { int t = ((p > 4) & (r < 5)) ? 2 : 55; s += cq_measure(t); }
    return cq_measure(q) + cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(3, 3); }
