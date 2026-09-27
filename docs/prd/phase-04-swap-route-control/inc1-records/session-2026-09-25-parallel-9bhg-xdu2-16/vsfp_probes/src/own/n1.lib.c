int h2(int a, int k);
int h(int a, int k) { return h2(a, k); }
__attribute__((noinline)) int h2(int a, int k) { return k + 1; }
