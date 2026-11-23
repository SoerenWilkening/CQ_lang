// bounds check with a throw on a quantum index
#include "cq.hpp"
#include <vector>
ENTRY int f(int x, int y) { std::vector<int> v{1, y, 3, 4}; return v.at(q((unsigned char)x) & 3) + v.at(1); }
