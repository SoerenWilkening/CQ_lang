/* tests/calls probe (cq-dxii, review w2a-qram-h1/t2): a classical loop storing into a QRAM object is not walked inline as pure classical
 * (it recorded one store for every trip: the bus was dirty at qram_free); it reaches loops-classical.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec qram_loop_columns.c -o qram_loop_columns.O1.ll */
#include "CQ.h"
#include <string.h>
struct in { short s; int i; };
struct cell { char c; double d; struct in n; };
int t2(unsigned x0, double t, int k) {
    unsigned x = x0;
    cq_theta(&x, t);
    struct cell arr[4];
    for (int j = 0; j < 4; j++) { arr[j].c = j; arr[j].d = j * 1.5; arr[j].n.s = 10 + j; arr[j].n.i = 100 + j; }
    arr[x & 3].n.i = k;
    arr[(x + 1) & 3].n.s = (short)k;
    arr[(x + 2) & 3].c = 9;
    return cq_measure(arr[x & 3].n.s + arr[(x+3)&3].n.i + arr[(x+2)&3].c + (int)arr[(x+1)&3].d + arr[1].n.i);
}
