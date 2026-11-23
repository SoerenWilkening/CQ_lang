#include "cq.hpp"
#include <sstream>
ENTRY int f(int x, int y) { std::ostringstream o; o << "v=" << q(x & 15); std::string s = o.str(); return s[2] + (int)s.size(); }
