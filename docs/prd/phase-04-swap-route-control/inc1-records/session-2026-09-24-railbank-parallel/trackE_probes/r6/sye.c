#include <stdio.h>
#include <stdlib.h>
__attribute__((noinline)) int w(int a, int k){ printf("a=%d\n", a); return k + 1; }
__attribute__((noinline)) int y(int a, int k){ return (a & 0x7fffffff) >= 0 ? k + 1 : k; }
__attribute__((noinline)) int run(int s, int m) { int q = cq_theta(s, 0.5); int t = y(q, m); int r = m; if (t > 3 && q > 1) r = m + 5; return cq_measure(r); }
int main(int argc, char **argv) { printf("%d\n", run(atoi(argv[1]), atoi(argv[2]))); return 0; }
