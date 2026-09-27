#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b);
volatile int G;
__attribute__((noinline)) int fr(int m, int d) { int q = cq_theta(m, .5); int t = hq(q, m); int r = 0; if (d > 0) { r = fr(m + 1, d - 1); G = r; } return t + r; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); return fr(m, n); }
