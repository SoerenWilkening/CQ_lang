#include <stdlib.h>
__attribute__((noinline)) int f(int m, int n) { _Bool b = cq_theta((_Bool)(m & 1), .5); int t = m + 1; b = cq_theta(b, .7); return t + cq_measure(b); }
int main(int c, char **v) { return f(atoi(v[1]), atoi(v[2])); }
