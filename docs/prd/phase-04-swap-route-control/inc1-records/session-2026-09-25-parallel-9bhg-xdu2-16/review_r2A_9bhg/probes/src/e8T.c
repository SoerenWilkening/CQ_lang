#include <stdlib.h>
#include <stdio.h>
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = m + 1; int r = 0; for (int i = 0; i < 3; i++) if (t > i) r = r + 1; return r; }
int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); return cq_measure(x) * 10 + x; }
