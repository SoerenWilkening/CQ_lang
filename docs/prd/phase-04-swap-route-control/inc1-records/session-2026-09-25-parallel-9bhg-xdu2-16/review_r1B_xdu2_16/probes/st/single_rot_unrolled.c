__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int s = 0;
    { int t = (q > 1) ? 0 : 55; t = cq_theta(t, 0.7); s += cq_measure(t); }
    { int t = (q > 1) ? 1 : 55; t = cq_theta(t, 0.7); s += cq_measure(t); }
    { int t = (q > 1) ? 2 : 55; t = cq_theta(t, 0.7); s += cq_measure(t); }
    return cq_measure(q) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
