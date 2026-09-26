#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
double hd(double a, double k); double hdq(double a, double k);
volatile int G;
__attribute__((noinline)) int fr(int m, int d) { int q = cq_theta(m, .5); if (d <= 0) return 0; int r = fr(m, d - 1); G = r; int t = h(q, r); return t; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); return fr(m, n); }
