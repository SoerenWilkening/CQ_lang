__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    { int u = r * 3 + 0; int t = (((q ^ m) > 1) & (r < 5)) ? u : 55; s += cq_measure(t); }
    { int u = r * 3 + 1; int t = (((q ^ m) > 1) & (r < 5)) ? u : 55; s += cq_measure(t); }
    { int u = r * 3 + 2; int t = (((q ^ m) > 1) & (r < 5)) ? u : 55; s += cq_measure(t); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
