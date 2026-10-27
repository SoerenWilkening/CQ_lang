/* Rule 26: a struct larger than 16 bytes is returned through an sret pointer; the callee writes the fields into the
 * caller's slot; a quantum field becomes a handle in that slot. */
struct big { long a, b, c; };
__attribute__((noinline)) static struct big mk(long x, long c) { struct big r = { x + c, x * c, c }; return r; }
long sret_return(long x0, double tx, long c) {
    long x = x0;
    cq_theta(&x, tx);
    struct big r = mk(x, c);
    return cq_measure(r.a + r.b + r.c);
}
