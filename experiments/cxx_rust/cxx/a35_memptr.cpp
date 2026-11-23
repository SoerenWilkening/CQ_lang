#include "cq.hpp"
struct S { int a, b; int f1(int k) { return a + k; } int f2(int k) { return b * k; } };
__attribute__((noinline)) int run(S *s, int (S::*m)(int), int S::*d, int k) { return (s->*m)(k) + s->*d; }
ENTRY int f(int x, int y) { S s{q(x), y}; return run(&s, &S::f1, &S::b, 3) + run(&s, &S::f2, &S::a, q(y)); }
