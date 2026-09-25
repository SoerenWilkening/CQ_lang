#include <stdlib.h>
#include <stdio.h>
int h(int a, int k); int g(int a); int g2(int a, int b);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int u = g(f(m)); return u; }
