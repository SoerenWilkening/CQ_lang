// a classical throw/catch beside quantum data
#include "cq.hpp"
__attribute__((noinline)) int g(int v, int y) { if (y < 0) throw 5; return v * 3; }
ENTRY int f(int x, int y) { int v = q(x); try { return g(v, y); } catch (int e) { return v + e; } }
