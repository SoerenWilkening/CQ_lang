#include "cq.hpp"
#include <unordered_map>
ENTRY int f(int x, int y) { std::unordered_map<int, int> m; m[1] = 10; m[5] = 20; m[3] = y; auto it = m.find(q(x) & 7); return it == m.end() ? -1 : it->second; }
