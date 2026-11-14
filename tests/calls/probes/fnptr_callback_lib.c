/* tests/calls probe (cq-yrgm, CR rule 19, §1.3, rule 16 "Entry"): a comparator whose address is passed to a bodiless library
 * function (qsort); host code calls its own symbol. The same comparator is also called through a pointer with a quantum
 * argument, so its table row is the one resolved.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec fnptr_callback_lib.c -o fnptr_callback_lib.O1.ll */
#include <stdlib.h>
#include "CQ.h"
__attribute__((noinline)) static int cmp(const void *a, const void *b) {
    int x = *(const int *)a, y = *(const int *)b;
    return (x > y) - (x < y);
}
int (*volatile pick)(const void *, const void *) = cmp;
int cb(int a0, int b0, int c0, double th) {
    int v[3] = {a0, b0, c0};
    qsort(v, 3, sizeof v[0], cmp);
    int x = v[0];
    cq_theta(&x, th);
    int y = v[2];
    return cq_measure(pick(&x, &y)) + v[1];
}
