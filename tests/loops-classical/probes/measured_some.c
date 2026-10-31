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
