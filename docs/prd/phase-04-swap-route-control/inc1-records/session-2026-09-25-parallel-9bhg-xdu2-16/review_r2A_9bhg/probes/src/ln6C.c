#include <stdlib.h>
#include <stdbool.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int c, char **v) { int m = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .3); int k = f(m); for (int i = 0; i < 3; i++) { q2 = cq_theta(q2, k * .1); } return cq_measure(q2); }
