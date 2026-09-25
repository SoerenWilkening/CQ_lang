#include <stdlib.h>
#include <stdio.h>
int h(int a, int k); int g(int a); int g2(int a, int b);
int main(int argc, char **argv) { int m = atoi(argv[1]); int q = cq_theta(m, .5); int t = h(q, m); int u = g2(t, q); return cq_measure(u); }
