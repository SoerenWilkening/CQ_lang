/* A quantum argument to a function that is not inlined (a clone). */
__attribute__((noinline)) int sq(int v) { return v * v + 1; }
int call_sq(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(sq(x));
}
