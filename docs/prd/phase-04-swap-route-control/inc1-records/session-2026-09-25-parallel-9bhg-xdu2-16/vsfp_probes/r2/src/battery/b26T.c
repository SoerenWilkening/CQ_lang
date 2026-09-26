#include <stdlib.h>
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; return t; }
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int u = f(m) + 1; b = cq_theta(b, .7); return u + cq_measure(b); }
