#include <stdlib.h>
int h(int a, int k);

__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int r = cq_theta(t, .2); int s = cq_measure(r); return t + s; }
int main(int c, char **v) { int m = atoi(v[1]); return f(m); }
