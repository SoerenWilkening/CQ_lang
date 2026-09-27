#include <stdlib.h>
int h(int a, int k); int hq(int a, int k); int g(int a); int g2(int a, int b); int gfirst(int a, int b);
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .25); int t1 = h(q, m); int t2 = h(m, q2); int u = g2(t1, t2); return cq_measure(u); }
