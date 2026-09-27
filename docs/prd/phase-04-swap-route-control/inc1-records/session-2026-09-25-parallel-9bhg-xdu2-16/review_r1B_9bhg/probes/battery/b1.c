#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
double hd(double a, double k); double hdq(double a, double k);
volatile int G;
__attribute__((noinline)) int f(int m) { double q = cq_theta((double)m, .5); double t = hd(q, (double)m); return (int)t; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); return f(m) * n; }
