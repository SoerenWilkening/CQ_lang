/* tests/calls probe (cq-s2zz, CR rule 19): a function pointer loaded at a quantum index (a QROM of callee tags)
 * whose candidate has a non-pure gate (a phase): each is its _ctl clone under tag == k; a candidate with a classical result
 * entering the select merge as a seed rail. Regenerate: clang -O1 -S -emit-llvm -target
 * x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec qrom_fn_ctl.c -o qrom_fn_ctl.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int rot(int v) { cq_phi(0.5); return v + 1; }
__attribute__((noinline)) static int plain(int v) { return v * 3; }
static int (*const fa[2])(int) = { rot, plain };
int qc_res(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(fa[x & 1](c + x));
}
__attribute__((noinline)) static int six(int v) { return 6; }
static int (*const fb[2])(int) = { plain, six };
int qc_cls(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(fb[x & 1](c + x));
}
