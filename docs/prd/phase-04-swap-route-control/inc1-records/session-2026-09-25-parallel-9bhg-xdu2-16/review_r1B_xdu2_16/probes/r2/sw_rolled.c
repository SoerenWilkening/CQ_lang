__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int u;
    switch (q) { case 1: u = 7; break; case 2: u = 9; break; default: u = 2; }
    int s = 0;
    for (int i = 0; i < n; ++i) { int t = ((u > 3) & (r < 5)) ? i : 55; s += cq_measure(t); }
    return cq_measure(q) + cq_measure(r) + cq_measure(u) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
