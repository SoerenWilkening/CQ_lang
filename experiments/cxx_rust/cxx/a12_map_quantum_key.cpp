#include "cq.hpp"
#include <map>
ENTRY int f(int x, int y) { std::map<int, int> m; m[1] = 10; m[5] = 20; m[3] = y; auto it = m.find(q(x)); return it == m.end() ? -1 : it->second; }
