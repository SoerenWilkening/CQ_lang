#include <stdlib.h>
int h(int a, int k); int ext_f(int a); int ext_g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y; if (q > 5) y = ext_f(7); else y = ext_g(9); int t = h(q, y); int u = t * 2; return cq_measure(u) + cq_measure(q) + cq_measure(y); }
