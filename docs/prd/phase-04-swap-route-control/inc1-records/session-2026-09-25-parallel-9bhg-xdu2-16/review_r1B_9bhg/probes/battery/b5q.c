#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b);
volatile int G;
__attribute__((noinline)) int fa(int m, int d); __attribute__((noinline)) int fb(int m, int d) { int q = cq_theta(m, .25); int t = hq(q, m); int r = 0; if (d > 0) { r = fa(m + 2, d - 1); G = r; } return t * 2 + r; }
__attribute__((noinline)) int fa(int m, int d) { int q = cq_theta(m, .5); int t = h(q, m); int r = 0; if (d > 0) { r = fb(m + 1, d - 1); G = r; } return t + r; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); return fa(m, n); }
