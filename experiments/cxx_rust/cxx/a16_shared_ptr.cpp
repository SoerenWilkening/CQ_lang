#include "cq.hpp"
#include <memory>
ENTRY int f(int x, int y) { auto a = std::make_shared<int>(q(x)); auto b = a; *b += y; return *a * (int)a.use_count(); }
