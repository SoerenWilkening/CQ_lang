#include <stdlib.h>
#include <stdbool.h>
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int x = f(m); int q2 = cq_theta(n, .3); int r = q2 + x; int s = r > 7 ? 1 : 0; return cq_measure(s) + cq_measure(q2); }
