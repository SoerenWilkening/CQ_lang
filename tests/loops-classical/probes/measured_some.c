/* cq-8lf8: a computed rail (y = 3x + 1) measured on an early return only (n == 7) is garbage on the loop path:
 * resolved there by recompute, copy, uncompute at the end of the unmeasured region (Uncompute,
 * resolveUnmeasured). The runner's measured group checks the kept rails at trip counts 2 and 3 (no garbage rail).
 * Regenerate measured_some.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx -include ../CQ_spec/CQ.h
 * measured_some.c -o measured_some.O1.ll */
int m_r8(int q0, double th, int n) {
    int x = q0; cq_theta(&x, th);
    int y = x * 3 + 1;
    if (n == 7) return cq_measure(y);
    for (int i = 0; i < n; i++) { y = y * 5 - x; }
    int r = y + 2;
    cq_theta(&x, th);
    return cq_measure(r) + cq_measure(x) * 7;
}
int m_r8b(int q0, double th, int n) {
    int x = q0; cq_theta(&x, th);
    int y = x * 3 + 1;
    if (n == 7) return cq_measure(y);
    for (int i = 0; i < n; i++) { y = y * y - x; }
    int r = y + 2;
    cq_theta(&x, th);
    return cq_measure(r) + cq_measure(x) * 7;
}
int m_r8c(int q0, double th, int n) {
    int x = q0; cq_theta(&x, th);
    int y = x * 3 + 1;
    if (n == 7) return cq_measure(y);
    for (int i = 0; i < n; i++) { y = y * 5 - x; }
    int r = y + 2;
    return cq_measure(r) + cq_measure(x) * 7;
}
/* cq-zpe8: y measured on one arm, the join loops, and a later measurement after the loop reads y on either arm:
 * the non-measuring arm keeps y (no clean-up before the later measurement; was use_after_free). §6 only. */
volatile int m_sink;
int m_join(int c, int n) {
    int x = 0; cq_theta(&x, 0.9);
    int y = x * 3 + 1;
    int r = 0;
    if (c) r = cq_measure(y);
    else m_sink = c;
    for (int i = 0; i < n; i++) r += 2;
    if (n > 3) r += 100 * cq_measure(y);
    return r;
}
/* cq-50qq: y measured on one arm; the join still reaches a later measurement (d), so the non-measuring arm keeps
 * y across the join; at the return, on the paths that measured it nowhere (c == 0, d == 0), y is cleaned under a
 * classical "measured on this path" flag. The runner checks the kept rails at c == d == 0 (no garbage rail). */
int m_join2(int c, int d) {
    int x = 0; cq_theta(&x, 0.9);
    int y = x * 3 + 1;
    int r;
    if (c) r = cq_measure(y);
    else { m_sink = c; r = 5; }
    if (d) r += 100 * cq_measure(y);
    return r;
}
