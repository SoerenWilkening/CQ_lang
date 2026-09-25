__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25); int s = 0;
    int p = q * 3;
    for (int i = 0; i < n; ++i) { s += cq_measure(p + i); }
    return cq_measure(q) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc + 2); }
