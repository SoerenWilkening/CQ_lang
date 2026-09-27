#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return h(q, m); }
volatile int G;
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q2 = cq_theta(n, .25); G = f(m); int u = q2 + G; return cq_measure(u); }
