#include <stdlib.h>
#include <stdio.h>
int h(int a, int k); int g(int a); int g2(int a, int b);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
__attribute__((noinline)) int f1(int m) { return f(m) * 2; }
int main(int argc, char **argv) { int m = atoi(argv[1]); return f1(m) + 1; }
