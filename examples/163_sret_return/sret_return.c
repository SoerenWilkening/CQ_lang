/* Rule 26: a struct larger than 16 bytes is returned through an sret pointer, an ordinary pointer formal; the callee's
 * field stores are kept bus stores at the caller's block (rules 5, 18, 20 b), and the caller reads the fields back as bus loads. */
struct big { long a, b, c; };
__attribute__((noinline)) static struct big mk(long x, long c) { struct big r = { x + c, x * c, c }; return r; }
long sret_return(long x0, double tx, long c) {
    long x = x0;
    cq_theta(&x, tx);
    struct big r = mk(x, c);
    return cq_measure(r.a + r.b + r.c);
}
