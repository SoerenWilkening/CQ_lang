#include "cq.hpp"
#include <deque>
#include <list>
ENTRY int f(int x, int y) { std::deque<int> d; std::list<int> l; for (int i = 0; i < 3; i++) { d.push_front(i + y); l.push_back(i); } d[1] = q(x); l.push_front(d[1] + 1); int s = 0; for (int e : d) s += e; for (int e : l) s = s * 2 - e; return s; }
