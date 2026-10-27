/* Rule 26: a nested struct returned by value ({ { int, int }, double } = 16 bytes, coerced { i64, double }); the inner
 * struct's field is quantum. */
struct in2 { int a, b; };
struct outer { struct in2 i; double w; };
__attribute__((noinline)) static struct outer mk(int x, int c, double w) {
    struct outer r = { { x + c, x * c }, w * 2 }; return r; }
double nested_struct_return(int x0, double tx, int c, double w) {
    int x = x0;
    cq_theta(&x, tx);
    struct outer r = mk(x, c, w);
    return cq_measure(r.i.a + r.i.b + r.w);
}
