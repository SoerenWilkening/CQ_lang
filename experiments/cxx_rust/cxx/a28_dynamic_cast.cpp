#include "cq.hpp"
struct B { virtual ~B() {} int v; }; struct D : B { int w; }; struct E1 : B {};
__attribute__((noinline)) int g(B *b) { if (D *d = dynamic_cast<D *>(b)) return d->w * 2; return b->v; }
ENTRY int f(int x, int y) { D d; d.w = q(x); d.v = 1; E1 e; e.v = q(y); return g(&d) + g(&e); }
