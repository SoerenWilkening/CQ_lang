/* f05 lib — NESTED clone (inner clone call + its _unc twin in the reverse) */
__attribute__((noinline)) int g(int k) { return k * 5; }
int h(int a, int k) { return g(k) + 1; }
