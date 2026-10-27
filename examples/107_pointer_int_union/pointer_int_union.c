#include <stdint.h>
union pv { int *p; uintptr_t v; };
int union_ptr_to_int(unsigned x0, double th, int w) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[2] = {1, 2}, b[2] = {3, 4};
    union pv u;
    u.p = (x & 1) ? a : b + 1;               /* write the pointer member: a quantum fat pointer */
    u.v += 4;                                /* read it as an integer, arithmetic, write it back */
    return cq_measure(*u.p + w);             /* read it as a pointer again and dereference */
}
int union_int_to_ptr(unsigned x0, double th, int w) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[4] = {w, w + 1, w + 2, w + 3};
    union pv u;
    u.v = (uintptr_t)a + 4 * (x & 3);        /* write the integer member: an address computed from a classical base */
    return cq_measure(*u.p);                 /* read the pointer member and dereference */
}
__attribute__((noinline)) static void bump(union pv *u) { u->v += 4; }   /* the union reaches memory: a slot */
int union_slot(unsigned x0, double th, int w) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[2] = {1, 2}, b[2] = {3, 4};
    union pv u;
    u.p = (x & 1) ? a : b;                   /* store ptr into the slot */
    bump(&u);                                /* the callee loads it as i64, adds, stores i64 */
    return cq_measure(*u.p + w);             /* load ptr from the slot and dereference */
}
