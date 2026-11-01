/* tests/calls probe (cq-oocu, 107's union_slot): a slot record's pointer-kind cell (two handles, tag and idx) that
 * a clone reads as an integer (ptrtoint at the load: provenance plus byte offset) and writes back (inttoptr at
 * the store: the tag stays, a new idx is the clone's slot result). Regenerate: clang -O1 -S -emit-llvm -target
 * x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec ptr_cell.c -o ptr_cell.O1.ll */
#include "CQ.h"
#include <stdint.h>
union pv { int *p; uintptr_t v; };
union pl { long *p; uintptr_t v; };
__attribute__((noinline)) static void step(union pv *u) { u->v += 8; }
__attribute__((noinline)) static void fwd(union pl *u) { u->v += 16; }
int pc_two(unsigned x0, double th, int w) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[4] = {w, w + 1, w + 2, w + 3}, b[4] = {7, 8, 9, 10};
    union pv u;
    u.p = (x & 2) ? a : b;
    step(&u);                 /* two cells on */
    return cq_measure(*u.p - (int)x);
}
int pc_long(unsigned x0, double th, long w) {
    unsigned x = x0;
    cq_theta(&x, th);
    long a[3] = {w, 2 * w, 3}, b[3] = {5, 6, -w};
    union pl u;
    u.p = (x & 1) ? a : b;
    fwd(&u);                  /* two 8-byte cells on */
    return cq_measure((int)*u.p);
}
