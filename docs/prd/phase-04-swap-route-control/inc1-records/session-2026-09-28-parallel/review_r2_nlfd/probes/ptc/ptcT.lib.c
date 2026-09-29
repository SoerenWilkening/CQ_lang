__attribute__((noinline)) int h2(int x, int k) { return k + x; }
__attribute__((noinline)) int h(int a, int k) { return h2(a, k) + 1; }
