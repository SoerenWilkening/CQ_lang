#include "cq.hpp"
__attribute__((noinline)) int base() { return 4; }
struct S { int v; S(int a) : v(a) {} };
static S &inst() { static S s(base()); return s; }
ENTRY int f(int x, int y) { return inst().v + q(x) * y; }
