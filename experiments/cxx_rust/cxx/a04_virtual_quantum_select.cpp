// a quantum condition chooses which object's virtual method runs: an indirect call through a quantum pointer
#include "cq.hpp"
struct Op { virtual int go(int) const = 0; };
struct Add : Op { int go(int v) const override { return v + 7; } };
struct Mul : Op { int go(int v) const override { return v * 3; } };
static Add A; static Mul M;
__attribute__((noinline)) int call(const Op *o, int v) { return o->go(v); }
ENTRY int f(int x, int y) { bool b = q((bool)(x & 1)); const Op *o = b ? (const Op *)&A : (const Op *)&M; return call(o, y); }
