// operator new under a quantum condition
#include "cq.hpp"
__attribute__((noinline)) int use(int *p) { return *p + 1; }
ENTRY int f(int x, int y) { int v = q(x); int r = y; if (v > 3) { int *p = new int(v); r = use(p); delete p; } return r; }
