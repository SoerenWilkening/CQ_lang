#include <stdlib.h>
/* rule 16 (rulings3 H): a by-name callee of a table clone is called after an event in its one clone, the own symbol's path
   included, with no other event in the module; then every ordinary host call of the module is an entry. srand: void; rand: its
   result read, the effect entry's rail, KEPT. */
__attribute__((noinline)) static int g(int x) { srand(7); return x + 1; }
__attribute__((noinline)) static int f(int q) { return g(q); }
__attribute__((noinline)) static int g2(int x) { return x + rand(); }
__attribute__((noinline)) static int f2(int q) { return g2(q); }
int (*volatile fp)(int) = f;
int (*volatile fp2)(int) = f2;
int m1(int v, double t) { int x = v; cq_theta(&x, t); int r = f(3); srand(9); return cq_measure(r + x); }
int m2(int v, double t) { int x = v; cq_theta(&x, t); int r = f2(x); return cq_measure(r); }
