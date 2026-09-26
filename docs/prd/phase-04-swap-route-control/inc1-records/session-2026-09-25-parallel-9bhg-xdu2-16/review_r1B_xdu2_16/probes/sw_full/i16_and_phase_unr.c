__attribute__((noinline)) static int slice(int n, int m) {
    short q = cq_theta((short)0, 0.25);
    short r = cq_theta((short)1, 0.5);
    int s = 0;
    { int t = ((q > 1) & (r < 5)) ? 0 : 55; if ((q > 1) & (r < 5)) cq_phi(0.3); s += cq_measure(t); }
    { int t = ((q > 1) & (r < 5)) ? 1 : 55; if ((q > 1) & (r < 5)) cq_phi(0.3); s += cq_measure(t); }
    { int t = ((q > 1) & (r < 5)) ? 2 : 55; if ((q > 1) & (r < 5)) cq_phi(0.3); s += cq_measure(t); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
