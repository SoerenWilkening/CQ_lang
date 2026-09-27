#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t + q; }
int main(int argc, char **argv) { int m = atoi(argv[1]); int n = atoi(argv[2]); int r = f(m); return r * n; }
