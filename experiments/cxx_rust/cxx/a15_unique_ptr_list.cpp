#include "cq.hpp"
#include <memory>
struct N { int v; std::unique_ptr<N> next; };
ENTRY int f(int x, int y) { std::unique_ptr<N> h; for (int i = 0; i < 4; i++) { auto n = std::make_unique<N>(); n->v = i == 2 ? q(x) : y; n->next = std::move(h); h = std::move(n); }
  int s = 0; for (N *p = h.get(); p; p = p->next.get()) s = s * 2 + p->v; return s; }
