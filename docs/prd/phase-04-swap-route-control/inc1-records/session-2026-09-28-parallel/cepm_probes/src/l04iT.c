#include <stdlib.h>
int g(int a);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); g(q); int t = m + 1; int r = t; if (m > 3) r = cq_theta(t, .2); int s = cq_measure(r); return t + s + cq_measure(q); }
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); return f(m); }
