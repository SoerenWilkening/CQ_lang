#include <stdio.h>
#include <stdlib.h>
__attribute__((noinline)) int g(int a, int k){ return k + 1 + (a & 0); }
__attribute__((noinline)) int h(int a, int k){ int z = a * 2; return k + 1; }
__attribute__((noinline)) int u(int a, int k){ return a > 100 ? k : k + 1; }
__attribute__((noinline)) int run(int s, int m) { int q = cq_theta(s, 0.5); int t = h(q, m); int r = m; if (t > 3 && q > 1) r = m + 5; return cq_measure(r); }
int main(int argc, char **argv) { printf("%d\n", run(atoi(argv[1]), atoi(argv[2]))); return 0; }
