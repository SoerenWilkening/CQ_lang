#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return hq(q, m); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q2 = cq_theta(n, .25); int t = f(m); if (q2 > t) cq_phi(3.14159); return cq_measure(q2); }
