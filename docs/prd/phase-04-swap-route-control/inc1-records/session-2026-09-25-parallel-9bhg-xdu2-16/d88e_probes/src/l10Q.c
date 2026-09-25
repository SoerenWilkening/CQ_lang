#include <stdlib.h>
int h(int a, int k);

int G;
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int t2 = h(q, m + 2); int r = t; if (m > 3) r = cq_theta(t, .2); G = cq_measure(r); return t2; }
int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); return x + G; }
