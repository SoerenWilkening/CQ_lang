#include "cq.hpp"
#include <algorithm>
#include <array>
#include <numeric>
ENTRY int f(int x, int y) { std::array<int, 6> a{1, y, 3, q(x), 5, 6};
  std::transform(a.begin(), a.end(), a.begin(), [y](int v) { return v * 2 + y; });
  return std::accumulate(a.begin(), a.end(), 0) + (int)std::count_if(a.begin(), a.end(), [](int v) { return v > 8; }) + *std::max_element(a.begin(), a.end()); }
