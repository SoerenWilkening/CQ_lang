/* r1A probe A2 depth 12: a chain of out-of-line callees, each reading its formal
   through the next level's clone AND a template, for a proof-walk cost probe. */
__attribute__((noinline)) int g12(int k) { return k + 1; }
__attribute__((noinline)) int g11(int k) { return g12(k) ^ g12(k ^ 13); }
__attribute__((noinline)) int g10(int k) { return g11(k) ^ g11(k ^ 12); }
__attribute__((noinline)) int g9(int k) { return g10(k) ^ g10(k ^ 11); }
__attribute__((noinline)) int g8(int k) { return g9(k) ^ g9(k ^ 10); }
__attribute__((noinline)) int g7(int k) { return g8(k) ^ g8(k ^ 9); }
__attribute__((noinline)) int g6(int k) { return g7(k) ^ g7(k ^ 8); }
__attribute__((noinline)) int g5(int k) { return g6(k) ^ g6(k ^ 7); }
__attribute__((noinline)) int g4(int k) { return g5(k) ^ g5(k ^ 6); }
__attribute__((noinline)) int g3(int k) { return g4(k) ^ g4(k ^ 5); }
__attribute__((noinline)) int g2(int k) { return g3(k) ^ g3(k ^ 4); }
__attribute__((noinline)) int g1(int k) { return g2(k) ^ g2(k ^ 3); }
__attribute__((noinline)) int g0(int k) { return g1(k) ^ g1(k ^ 2); }
int h(int a, int k) { return g0(k); }
