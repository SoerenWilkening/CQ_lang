#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
double hd(double a, double k); double hdq(double a, double k);
volatile int G;
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25); int t = h(q, m); int s = t; for (int i = 0; i < 4; i++) { if (q2 > 3) s = s + 1; } return cq_measure(s); }
