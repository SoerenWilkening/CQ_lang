// vector growth under a quantum condition
#include "cq.hpp"
#include <vector>
ENTRY int f(int x, int y) { int v = q(x); std::vector<int> a; a.reserve(4); a.push_back(1); if (v > 3) a.push_back(v); if (v & 1) a.push_back(y); int s = 0; for (int e : a) s = s * 2 + e; return s; }
