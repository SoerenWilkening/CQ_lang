/* r1A probe A2 depth 6: a chain of out-of-line callees, each reading its formal
   through the next level's clone AND a template, for a proof-walk cost probe. */
__attribute__((noinline)) int g6(int k) { return k + 1; }
__attribute__((noinline)) int g5(int k) { return g6(k) ^ g6(k ^ 7); }
__attribute__((noinline)) int g4(int k) { return g5(k) ^ g5(k ^ 6); }
__attribute__((noinline)) int g3(int k) { return g4(k) ^ g4(k ^ 5); }
__attribute__((noinline)) int g2(int k) { return g3(k) ^ g3(k ^ 4); }
__attribute__((noinline)) int g1(int k) { return g2(k) ^ g2(k ^ 3); }
__attribute__((noinline)) int g0(int k) { return g1(k) ^ g1(k ^ 2); }
int h(int a, int k) { return g0(k); }
