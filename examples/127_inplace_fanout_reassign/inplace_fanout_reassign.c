__attribute__((noinline)) static int f(int a, int b) { return a * b + a; }
int inplace_fanout_reassign(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int y = x + 1;            /* fan-out: x has three consumers */
    int z = x * c;
    x = f(x, y);              /* reassignment from a quantum-quantum call */
    x ^= z;                   /* reassignment from a quantum-quantum op */
    return cq_measure(x);     /* y, z and f(x, y) are dead: each uncomputed exactly once */
}
