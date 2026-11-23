#include "cq.hpp"
#include <ranges>
#include <array>
ENTRY int f(int x, int y) { std::array<int, 6> a{1, 2, q(x), 4, y, 6}; int s = 0; for (int v : a | std::views::filter([](int v) { return v % 2 == 0; }) | std::views::transform([](int v) { return v * v; })) s += v; return s; }
