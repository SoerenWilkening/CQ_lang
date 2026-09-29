#include <stdlib.h>
int h(int a, int k);
int g4(int a, int b);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int t = h(q, m); int u = g4(t, q); return cq_measure(u) + cq_measure(q); }
