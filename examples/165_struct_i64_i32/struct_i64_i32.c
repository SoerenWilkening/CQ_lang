/* Rule 26: a 12-byte struct { long, int } coerced to { i64, i32 } at the ABI, by value in and out of a callee, quantum
 * in the int field (first entry) and in both (second). */
struct li { long a; int b; };
__attribute__((noinline)) static struct li bump(struct li p, int c) { struct li r = { p.a + c, p.b - c }; return r; }
long struct_i64_i32_one(long a, int b0, double tb, int c) {
    struct li p = { a, b0 };
    cq_theta(&p.b, tb);
    struct li r = bump(p, c);
    return cq_measure(r.a + r.b);
}
long struct_i64_i32_both(long a0, double ta, int b0, double tb, int c) {
    struct li p = { a0, b0 };
    cq_theta(&p.a, ta);
    cq_theta(&p.b, tb);
    struct li r = bump(p, c);
    return cq_measure(r.a) + cq_measure(r.b);
}
