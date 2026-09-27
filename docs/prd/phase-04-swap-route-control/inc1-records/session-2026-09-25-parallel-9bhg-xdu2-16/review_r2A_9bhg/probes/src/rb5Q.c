#include <stdlib.h>
#include <stdbool.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int x = f(m); _Bool b = cq_theta((_Bool)(n & 1), .5); int p = b ? x : 4; return cq_measure(p) + cq_measure(b); }
