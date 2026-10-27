/* Rule 26: a struct larger than 16 bytes passed by value (byval pointer to a caller copy) with one quantum field and,
 * in the second entry, two. */
struct big { long a, b, c; };
__attribute__((noinline)) static long sum3(struct big p, long c) { return p.a + p.b * c + p.c; }
long byval_large_one(long x0, double tx, long b, long c) {
    struct big p = { x0, b, c };
    cq_theta(&p.a, tx);
    return cq_measure(sum3(p, c));
}
long byval_large_two(long x0, double tx, long y0, double ty, long c) {
    struct big p = { x0, y0, c };
    cq_theta(&p.a, tx);
    cq_theta(&p.b, ty);
    return cq_measure(sum3(p, c));
}
