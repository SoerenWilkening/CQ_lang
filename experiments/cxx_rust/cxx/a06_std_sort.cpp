#include "cq.hpp"
#include <algorithm>
ENTRY int f(int x, int y) { int a[4] = {q(x), y, 2, 9}; std::sort(a, a + 4); return a[0] + 3 * a[1] + 5 * a[2] + 7 * a[3]; }
