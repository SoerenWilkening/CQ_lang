__attribute__((noinline)) static int dbl(int v) { return v + v; }
__attribute__((noinline)) static int sq(int v)  { return v * v; }
int indirect_call(int x0, double th, int which) {
    int x = x0;
    cq_theta(&x, th);
    int (*fp)(int) = which ? dbl : sq;       /* classical function pointer, chosen at run time */
    return cq_measure(fp(x));
}
