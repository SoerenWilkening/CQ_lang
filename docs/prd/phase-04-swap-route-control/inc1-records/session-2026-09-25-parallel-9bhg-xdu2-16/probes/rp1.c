#include <stdlib.h>
int h(int a, int k); int ext_f(int x);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int r = m; if (q > 3) r = t + 2; return r; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return f(m) * 3; }
