#include "cq.hpp"
#include <string>
ENTRY int f(int x, int y) { std::string s = "ab"; s += q((char)x); s += "cd"; return (s == "abXcd") + 2 * (int)(s < "abc") + 4 * (int)s.size(); }
