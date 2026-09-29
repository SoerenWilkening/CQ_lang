__attribute__((noinline)) int h2(int a, int k) { return a + k; }
__attribute__((noinline)) int h1(int a, int k) { return h2(a, k); }
int h(int a, int k) { return h1(a, k); }
