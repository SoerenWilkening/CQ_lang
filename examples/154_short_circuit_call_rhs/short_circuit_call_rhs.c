/* Rule 8: a short-circuit `&&` whose right operand is a noinline call, so -O1 keeps the diamond instead of folding
 * to `and i1`. The call is lifted (rule 18) and evaluated unguarded; its compare flag is conjoined with the left flag. */
__attribute__((noinline)) static int f(int x, int c) { return x * c + 1; }
int short_circuit_call_rhs(int x0, double tx, int k, int c, int m, double p) {
    int x = x0;
    cq_theta(&x, tx);
    if (x > k && f(x, c) == m) cq_phi(p);
    cq_theta(&x, -tx);
    return cq_measure(x);
}
