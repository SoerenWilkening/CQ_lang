/* tests/calls probe (cq-noavf, CR rule 19, §1.1): virtual calls through a table of function pointers in a classically
 * bounded loop, the entry returning the unmeasured sum. The loop's clone returns an aggregate { result, ... }, so the
 * entry's handle is an extractvalue of it: the checker must read that ret as a handle, not as the value.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../spec fnptr_vtable_loop_ret.c -o fnptr_vtable_loop_ret.O1.ll */
#include "CQ.h"
struct Shape;
struct VT { int (*area)(const struct Shape *, int); };
struct Shape { const struct VT *vt; int a, b; };
static int sq(const struct Shape *s, int k) { return s->a * s->a + k; }
static int rect(const struct Shape *s, int k) { return s->a * s->b - k; }
static const struct VT VS = {sq}, VR = {rect};
__attribute__((noinline)) int total(const struct Shape *const *s, int n, int k) {
    int t = 0;
    for (int i = 0; i < n; i++)
        t += s[i]->vt->area(s[i], k);
    return t;
}
int vt(int x, int y) {
    int qx = x, qy = y;
    cq_theta(&qx, 0.5);
    cq_theta(&qy, 0.5);
    struct Shape s = {&VS, qx, 0}, r = {&VR, x, y};
    const struct Shape *v[2] = {&s, &r};
    return total(v, 2, qy);
}
