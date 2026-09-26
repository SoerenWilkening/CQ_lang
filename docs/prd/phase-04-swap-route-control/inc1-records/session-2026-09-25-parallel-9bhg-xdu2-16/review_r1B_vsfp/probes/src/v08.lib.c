int inner(int a, int k) { volatile int z = a; return k + 1; }
int h(int a, int k) { int p = (a & 1) ? 9 : 4; return inner(p, k); }
