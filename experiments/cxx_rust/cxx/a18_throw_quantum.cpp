// throw under a quantum condition
#include "cq.hpp"
__attribute__((noinline)) int g(int v) { if (v < 0) throw 5; return v * 3; }
ENTRY int f(int x, int y) { int v = q(x); try { return g(v); } catch (int e) { return y + e; } }
