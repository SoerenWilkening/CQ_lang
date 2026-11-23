#include "cq.hpp"
#include <vector>
ENTRY int f(int x, int y) { std::vector<int> v; for (int i = 0; i < 5; i++) v.push_back(i * y); v[2] = q(x); int s = 0; for (int e : v) s += e > 3 ? e : -e; return s; }
