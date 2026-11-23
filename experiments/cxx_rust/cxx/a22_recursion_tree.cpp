#include "cq.hpp"
struct T { int k; T *l, *r; };
static int sum(const T *t, int lim) { return t ? (t->k < lim ? t->k : lim) + sum(t->l, lim) + sum(t->r, lim) : 0; }
ENTRY int f(int x, int y) { T a{1, 0, 0}, b{q(x), 0, 0}, c{y, &a, &b}, d{4, 0, &c}; return sum(&d, 6); }
