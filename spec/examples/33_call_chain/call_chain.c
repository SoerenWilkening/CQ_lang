__attribute__((noinline)) static int h(int v, int c) { return v + c; }
__attribute__((noinline)) static int g(int v, int c) { return h(v, c) * v; }
__attribute__((noinline)) static int f(int v, int c) { return g(v, c) - c; }
int call_chain(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(f(x, c));
}
