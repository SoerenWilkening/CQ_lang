#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); return hq(q, m); }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q2 = cq_theta(n, .25); int r; switch (f(m)) { case 1: r = q2 + 1; break; case 6: r = q2 * 3; break; default: r = q2; } return cq_measure(r); }
