void g(int a);
struct P { int a, b; };
struct P hs(int a, int k) { g(a); struct P r = { k + 1, k * 2 }; return r; }
