__attribute__((noinline)) static int rot(int x) { return cq_theta(x, 0.3); }
__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int s = 0;
    for (int i = 0; i < n; ++i) { int t = (q > 1) ? i : 55; s += cq_measure(t); s += cq_measure(rot(q)); }
    return s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
