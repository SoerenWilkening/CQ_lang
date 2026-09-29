#include <stdlib.h>
int ext_f(int a);
int g2(int a, int b);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); int t = m + 1; int u = g2(t, q); return cq_measure(u) + cq_measure(q) + cq_measure(y); }
