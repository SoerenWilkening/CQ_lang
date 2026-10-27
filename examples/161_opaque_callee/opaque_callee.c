/* Rule 27: an external callee with no body (declared only) called with a quantum argument is a call to the
 * declared clone __cq_q_ext_fn_10; the definition comes from whatever is linked (else an ordinary link error). */
int ext_fn(int, int);
int opaque_callee(int x0, double tx, int c) {
    int x = x0;
    cq_theta(&x, tx);
    int r = ext_fn(x, c);
    return r + cq_measure(x);
}
