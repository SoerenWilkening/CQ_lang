__attribute__((noinline)) int h2(int a, int k) { return k + a; }
int h(int a, int k) { return h2(a, k); }
