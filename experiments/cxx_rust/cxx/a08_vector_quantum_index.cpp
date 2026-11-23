#include "cq.hpp"
#include <vector>
ENTRY int f(int x, int y) { std::vector<int> v(8, y); unsigned i = q((unsigned char)x) & 7; v[i] += 5; return v[(i + 1) & 7] * 2 + v[3]; }
