#include "cq.hpp"
struct A { int a; virtual int fa() { return a; } }; struct B { int b; virtual int fb() { return b; } };
struct C : virtual A, B { int c; int fa() override { return a + c; } int fb() override { return b - c; } };
__attribute__((noinline)) int run(A *a, B *b) { return a->fa() * 3 + b->fb(); }
ENTRY int f(int x, int y) { C c; c.a = q(x); c.b = y; c.c = 2; return run(&c, &c); }
