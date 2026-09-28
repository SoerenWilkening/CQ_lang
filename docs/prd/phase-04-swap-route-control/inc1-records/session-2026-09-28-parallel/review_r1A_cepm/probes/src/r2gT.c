#include <stdlib.h>
void g(int a);
int ext_f(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int y = 0; if (q > 5) y = ext_f(7); g(q); int t = y + 1; int u = t * 2; return cq_measure(u) + cq_measure(q) + cq_measure(y); }
