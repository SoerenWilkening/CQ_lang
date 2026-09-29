#include <stdlib.h>
int h(int a, int k); int ext_f(int a); int ext_g(int a); int ext_k(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y; switch (q) { case 1: y = ext_f(7); break; case 6: y = ext_g(9); break; default: y = ext_k(3); } int t = h(q, y); int u = t * 2; return cq_measure(u) + cq_measure(q) + cq_measure(y); }
