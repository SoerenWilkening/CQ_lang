__attribute__((noinline)) static int dbl(int v) { return v + v; }
__attribute__((noinline)) static int sq(int v)  { return v * v; }
static int (*const fps[2])(int) = { dbl, sq };
int quantum_fnptr(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(fps[x & 1](c + x));     /* the callee is chosen by a quantum bit */
}
