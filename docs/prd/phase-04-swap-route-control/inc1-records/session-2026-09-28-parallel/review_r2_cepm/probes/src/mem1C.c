#include <stdlib.h>
int h(int a, int k); int rdG(int k); void stG(int v);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); stG(q); int y = rdG(n); int t = h(q, y); int q2 = cq_theta(n, .4); if (t > 3) q2 = cq_theta(q2, .2); return cq_measure(q2) + cq_measure(q); }
