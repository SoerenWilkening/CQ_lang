// a destructor run around a call that may unwind: invoke/landingpad with nothing thrown
#include "cq.hpp"
int log_[4], n_;
struct G { int id; G(int i) : id(i) {} ~G() { log_[n_++ & 3] = id; } };
__attribute__((noinline)) int h(int v, int y) { if (y == 12345) throw 1; return v ^ y; }
ENTRY int f(int x, int y) { G g(3); int r = h(q(x), y); return r + 1; }
