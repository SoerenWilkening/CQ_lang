#include "cq.hpp"
#include <queue>
ENTRY int f(int x, int y) { std::priority_queue<int> p; p.push(5); p.push(q(x)); p.push(y); int a = p.top(); p.pop(); return a * 3 + p.top(); }
