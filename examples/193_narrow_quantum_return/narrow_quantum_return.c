/* Rule 19 / §1.1: an ENTRY returning an UNMEASURED quantum value whose C type is narrower than the i32 handle. A handle
 * cannot be narrowed into a _Bool or a short (truncating it names another rail) and the compiler never measures a value
 * the program does not measure, so the external signature's return type becomes i32, the handle; the parameter list
 * keeps the C ABI. An integer return of 32 bits or more keeps its C type and carries the handle zero-extended (162: i32;
 * here long: i64). The returned rail escapes and is never freed; a dead old register under a bijective update is still
 * cleaned before the return (rule 6). The consumers are ordinary in-module callers: clang inlines the entries at -O1. */
_Bool narrow_return_bool(int x0, double tx, int k) {
    int x = x0;
    cq_theta(&x, tx);
    return x > k;                          /* i1 rail: the entry returns its i32 handle */
}
short narrow_return_short(short s0, double ts, short c) {
    short s = s0;
    cq_theta(&s, ts);
    return s + c;                          /* i16 rail: the entry returns its i32 handle; the old s is cleaned (rule 6) */
}
long wide_return_long(long x0, double tx, long c) {
    long x = x0;
    cq_theta(&x, tx);
    return x ^ c;                          /* i64 return: the handle zero-extended; the old x is cleaned (rule 6) */
}
int narrow_bool_consumer(int x0, double tx, int k) {
    return cq_measure(narrow_return_bool(x0, tx, k) ? 5 : 2);
}
int narrow_short_consumer(short s0, double ts, short c) {
    return cq_measure((short)(narrow_return_short(s0, ts, c) * 2));
}
long wide_long_consumer(long x0, double tx, long c) {
    return cq_measure(wide_return_long(x0, tx, c) + 1);
}
