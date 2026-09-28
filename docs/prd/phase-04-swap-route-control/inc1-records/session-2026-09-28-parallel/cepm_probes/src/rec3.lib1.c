void g(int a);
int k3(int k) { if (k <= 0) return 1; return k3(k - 1) + 2; }
int h(int a, int k) { g(a); return k3(k); }
