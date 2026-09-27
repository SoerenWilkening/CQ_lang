#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m, int n) { _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b + 1; int t = h(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }
int main(int c, char **v) { return f(atoi(v[1]), atoi(v[2])); }
