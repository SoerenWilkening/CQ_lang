__attribute__((noinline)) static int rot(int x) { return cq_theta(x, 0.3); }
__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    { int t = ((q > 1) & (r < 5)) ? 0 : 55; s += cq_measure(t); s += cq_measure(rot(q)); }
    { int t = ((q > 1) & (r < 5)) ? 1 : 55; s += cq_measure(t); s += cq_measure(rot(q)); }
    { int t = ((q > 1) & (r < 5)) ? 2 : 55; s += cq_measure(t); s += cq_measure(rot(q)); }
    return cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
