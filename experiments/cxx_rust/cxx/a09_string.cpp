#include "cq.hpp"
#include <string>
ENTRY int f(int x, int y) { std::string s = "hello quantum world, long enough for heap"; s[3] = q((char)x); int h = 0; for (char c : s) h = h * 31 + c; return h + (int)s.find('q'); }
