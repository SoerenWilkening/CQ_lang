#include <stdlib.h>
#include <stdio.h>
int h(int a, int k); int g(int a); int g2(int a, int b);
__attribute__((noinline)) int f(int m, int c) { int q = cq_theta(m, .5); int t; if (c > 2) t = h(q, m); else t = h(q, m + 1); return t; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int c = atoi(argv[2]); return f(m, c); }
