#include <stdlib.h>
#include <stdbool.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
double hd(double a, double k); double hdq(double a, double k);
volatile int G;
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); bool b = cq_theta((bool)(n & 1), .25); int u = h(q, m); if (b) u = cq_theta(u, 0.3); return cq_measure(u) + cq_measure(b); }
