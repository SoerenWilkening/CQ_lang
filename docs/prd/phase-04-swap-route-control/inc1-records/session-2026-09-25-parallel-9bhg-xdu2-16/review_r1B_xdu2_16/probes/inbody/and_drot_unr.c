__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int w = cq_theta(2, 0.4);
    int s = 0;
    { int t = ((q > 1) & (r < 5)) ? 0 : 55; int d = (t + r) > 7; t = cq_theta(t, 0.7); s += cq_measure(t) + cq_measure(d); }
    { int t = ((q > 1) & (r < 5)) ? 1 : 55; int d = (t + r) > 7; t = cq_theta(t, 0.7); s += cq_measure(t) + cq_measure(d); }
    { int t = ((q > 1) & (r < 5)) ? 2 : 55; int d = (t + r) > 7; t = cq_theta(t, 0.7); s += cq_measure(t) + cq_measure(d); }
    return cq_measure(q) + cq_measure(r) + cq_measure(w) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
