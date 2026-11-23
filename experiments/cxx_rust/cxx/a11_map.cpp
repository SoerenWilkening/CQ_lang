#include "cq.hpp"
#include <map>
ENTRY int f(int x, int y) { std::map<int, int> m; m[1] = 10; m[5] = q(x); m[3] = y; int s = 0; for (auto &[k, v] : m) s = s * 3 + k * v; return s; }
