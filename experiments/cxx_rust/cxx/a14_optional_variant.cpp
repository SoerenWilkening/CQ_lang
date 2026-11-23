#include "cq.hpp"
#include <optional>
#include <variant>
static std::optional<int> sdiv(int a, int b) { if (b == 0) return std::nullopt; return a / b; }
ENTRY int f(int x, int y) { auto r = sdiv(y & 255, q(x) & 3); std::variant<int, float> v; if (r) v = *r; else v = 2.5f;
  return std::visit([](auto t) { return (int)(t * 2); }, v); }
