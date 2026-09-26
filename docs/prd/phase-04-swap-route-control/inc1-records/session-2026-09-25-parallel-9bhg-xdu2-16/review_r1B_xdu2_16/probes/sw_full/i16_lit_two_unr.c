__attribute__((noinline)) static int slice(int n, int m) {
    short q = cq_theta((short)0, 0.25);
    short r = cq_theta((short)1, 0.5);
    int s = 0;
    { int t = ((q > 1) & (m > 0)) ? 0 : 55; int u = ((q > 1) & (m > 0)) ? 7 : 0; s += cq_measure(t) + cq_measure(u); }
    { int t = ((q > 1) & (m > 0)) ? 1 : 55; int u = ((q > 1) & (m > 0)) ? 7 : 1; s += cq_measure(t) + cq_measure(u); }
    { int t = ((q > 1) & (m > 0)) ? 2 : 55; int u = ((q > 1) & (m > 0)) ? 7 : 2; s += cq_measure(t) + cq_measure(u); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
