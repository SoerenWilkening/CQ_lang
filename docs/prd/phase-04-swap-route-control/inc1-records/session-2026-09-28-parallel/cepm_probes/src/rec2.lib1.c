void g(int a);
int k2(int k) { if (k <= 1) return k; return k2(k - 1) + k2(k - 2); }
int h(int a, int k) { g(a); return k2(k); }
