#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int m2 = atoi(v[2]); int q = cq_theta(m, .5); int t = h(q, m); int r = t; int x = 0; if (m2 > 3) r = cq_theta(t, .2); else x = (int)cq_measure(t); return (int)cq_measure(r) + x; }
