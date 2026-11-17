/* Rule 26: a struct with a quantum field passed BY VALUE into a noinline callee and returned by value; both fields
 * quantum in the second entry. clang coerces { int, int } to i64 at the ABI: the clone takes the field handles. */
struct p2 { int a, b; };
__attribute__((noinline)) static struct p2 shift(struct p2 p, int c) { struct p2 r = { p.a + c, p.b * c }; return r; }
int struct_byvalue_one(int a0, double ta, int b, int c) {
    struct p2 p = { a0, b };
    cq_theta(&p.a, ta);
    struct p2 r = shift(p, c);
    return cq_measure(r.a + r.b);
}
int struct_byvalue_both(int a0, double ta, int b0, double tb, int c) {
    struct p2 p = { a0, b0 };
    cq_theta(&p.a, ta);
    cq_theta(&p.b, tb);
    struct p2 r = shift(p, c);
    return cq_measure(r.a) + cq_measure(r.b);
}
