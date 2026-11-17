/* Rule 19: a function-pointer rail loaded from the bus; one of its candidates measures. */
__attribute__((noinline)) static int inc(int v) { return v + 1; }
__attribute__((noinline)) static int peek(int v) { return cq_measure(v); }   /* a measuring candidate */
static int (*ops[2])(int) = { inc, peek };
int fnptr_rail_measuring(unsigned k0, double tk, int x0, double tx) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int x = x0;
    cq_theta(&x, tx);
    return cq_measure(ops[k & 1](x));         /* the callee address is loaded at an address rail */
}
