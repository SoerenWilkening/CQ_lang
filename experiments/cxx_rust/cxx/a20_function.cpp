#include "cq.hpp"
#include <functional>
ENTRY int f(int x, int y) { std::function<int(int)> g = [y](int v) { return v + y; }; std::function<int(int)> k = [g](int v) { return g(v) * 2; }; return k(q(x)); }
