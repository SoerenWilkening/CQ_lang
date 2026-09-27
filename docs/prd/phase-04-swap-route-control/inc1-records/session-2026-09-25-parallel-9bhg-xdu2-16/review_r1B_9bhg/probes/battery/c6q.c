#include <stdlib.h>
#include <stdbool.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
double hd(double a, double k); double hdq(double a, double k);
volatile int G;
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25); int t1 = hq(q, m); int u = gfirst(t1, q); int r = u > n ? q2 + 1 : q2; return cq_measure(r) + cq_measure(q); }
