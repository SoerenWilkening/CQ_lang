/* §1.1: an entry function returning an UNMEASURED quantum value. The return keeps the C type at the external signature;
 * the value returned is the i32 handle widened/narrowed to that type (an escaped rail, never freed). The second entry
 * consumes such a value from a sibling. */
__attribute__((noinline)) int quantum_return_entry(int x0, double tx, int c) {
    int x = x0;
    cq_theta(&x, tx);
    return x + c;
}
int quantum_return_consumer(int x0, double tx, int c) {
    int q = quantum_return_entry(x0, tx, c);
    return cq_measure(q * 2);
}
