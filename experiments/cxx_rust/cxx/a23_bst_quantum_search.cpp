#include "cq.hpp"
struct T { int k, v; const T *l, *r; };
static const T t1{1, 11, 0, 0}, t3{3, 33, 0, 0}, t2{2, 22, &t1, &t3}, t6{6, 66, 0, 0}, t4{4, 44, &t2, &t6};
ENTRY int f(int x, int y) { int k = q(x); const T *p = &t4; while (p) { if (k == p->k) return p->v; p = k < p->k ? p->l : p->r; } return y; }
