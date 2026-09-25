__attribute__((noinline)) static int slice(int n, int m) {
    signed char q = cq_theta((signed char)0, 0.25);
    signed char r = cq_theta((signed char)1, 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) { int t = ((q > 1) & (r < 5)) ? i : 55; int d = (r + i) > 3; s += cq_measure(t) + cq_measure(d); }
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
