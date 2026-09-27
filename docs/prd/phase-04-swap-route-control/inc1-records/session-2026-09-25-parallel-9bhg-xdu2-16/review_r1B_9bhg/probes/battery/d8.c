#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
int gx(int a, int b); int gy(int a, int b);
double hd(double a, double k); double hdq(double a, double k);
static const int TB[8] = {3,1,4,1,5,9,2,6};
volatile int G;
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int q9 = cq_theta(m, .4); if (q9 > 2) cq_phi(0.7); int t = h(q, m); return t + cq_measure(q9); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(n, .5); int u = gx(f(m), q); int v = gy(f(n), q); return cq_measure(u) + cq_measure(v); }
