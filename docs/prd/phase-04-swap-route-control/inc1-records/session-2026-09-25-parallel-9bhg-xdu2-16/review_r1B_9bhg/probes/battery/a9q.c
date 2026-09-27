#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
__attribute__((noinline)) int fr(int m, int d) { if (d <= 0) return 0; int q = cq_theta(m, .5); int t = hq(q, m); return t + fr(m, d - 1); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); return fr(m, n); }
