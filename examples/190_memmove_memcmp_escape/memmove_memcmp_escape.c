#define _FORTIFY_SOURCE 0
#include <string.h>
/* Memory intrinsics and library calls over cells holding quantum values (rules 20, 22, 27). */
extern void ext_sink(int *p, int n);
int memmove_overlap(int x0, double tx, int y0, double ty, unsigned j) {
    int x = x0;
    cq_theta(&x, tx);
    int y = y0;
    cq_theta(&y, ty);
    int a[4] = {x, y, 5, 6};
    memmove(a + 1, a, 3 * sizeof(int));       /* overlapping: a = {x, x, y, 5} */
    return cq_measure(a[j & 3] + 1);
}
int memcmp_qlen(unsigned x0, double tx, unsigned char u0, double tu, unsigned char v0, double tv) {
    unsigned x = x0;
    cq_theta(&x, tx);
    unsigned char u = u0;
    cq_theta(&u, tu);
    unsigned char v = v0;
    cq_theta(&v, tv);
    unsigned char a[3] = {u, v, u}, b[3] = {u, u, v};
    int c = memcmp(a, b, x & 3);              /* quantum length n <= 3 */
    return cq_measure((c > 0) - (c < 0));     /* n >= 2 ? sign(v - u) : 0 */
}
int escape(int x0, double tx) {
    int x = x0;
    cq_theta(&x, tx);
    int a[2] = {x, x + 1};
    ext_sink(a, 2);                           /* body-less callee: a declared clone (rule 27) */
    return cq_measure(a[0]);                  /* re-read after the call: whatever the cell holds */
}
