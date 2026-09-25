#include <stdlib.h>
#include <stdio.h>
int h(int a, int k); int g(int a); int g2(int a, int b);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int q2 = cq_theta(m, .25); int u = g2(f(m), q2); return cq_measure(u); }
