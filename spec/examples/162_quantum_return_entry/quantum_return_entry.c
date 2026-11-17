/* §1.1, rule 19: an entry function returning an UNMEASURED quantum value. The value returned is the i32 handle (an
 * escaped rail, never freed); an int return holds it as is (a narrower C return type becomes i32, a wider one carries the
 * handle zero-extended: 193). The second entry consumes such a value from a sibling. */
__attribute__((noinline)) int quantum_return_entry(int x0, double tx, int c) {
    int x = x0;
    cq_theta(&x, tx);
    return x + c;
}
int quantum_return_consumer(int x0, double tx, int c) {
    int q = quantum_return_entry(x0, tx, c);
    return cq_measure(q * 2);
}
