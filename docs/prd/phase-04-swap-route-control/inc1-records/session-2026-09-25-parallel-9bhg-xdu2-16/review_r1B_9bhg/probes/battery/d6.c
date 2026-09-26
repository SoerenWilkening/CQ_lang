#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
int gx(int a, int b); int gy(int a, int b);
double hd(double a, double k); double hdq(double a, double k);
static const int TB[8] = {3,1,4,1,5,9,2,6};
volatile int G;
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25); int r = q2; if (q > 3) r = q2 + 5; int u = gx(m, q); int v = gy(n, q); return cq_measure(u) + cq_measure(v) + cq_measure(r); }
