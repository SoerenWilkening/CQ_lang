__attribute__((noinline)) static int f(int v, int c) {
    int s = v * v;
    return s + c;
}

int call_tainted_arg(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int y = f(x, c);
    return cq_measure(y);
}
