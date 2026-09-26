#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
double hd(double a, double k); double hdq(double a, double k);
volatile int G;
__attribute__((noinline)) int fr(int m, int d) { if (d <= 0) return 0; int q = cq_theta(m, .5); int t = h(q, m); int r = fr(m, d - 1); G = r; return t + r; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); return fr(m, n); }
