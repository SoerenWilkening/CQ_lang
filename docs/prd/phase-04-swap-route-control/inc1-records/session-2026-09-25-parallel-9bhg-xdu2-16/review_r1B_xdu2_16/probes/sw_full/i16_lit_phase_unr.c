__attribute__((noinline)) static int slice(int n, int m) {
    short q = cq_theta((short)0, 0.25);
    short r = cq_theta((short)1, 0.5);
    int s = 0;
    { int t = ((q > 1) & (m > 0)) ? 0 : 55; if ((q > 1) & (m > 0)) cq_phi(0.3); s += cq_measure(t); }
    { int t = ((q > 1) & (m > 0)) ? 1 : 55; if ((q > 1) & (m > 0)) cq_phi(0.3); s += cq_measure(t); }
    { int t = ((q > 1) & (m > 0)) ? 2 : 55; if ((q > 1) & (m > 0)) cq_phi(0.3); s += cq_measure(t); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
