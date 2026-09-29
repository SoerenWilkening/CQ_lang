#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .4); for (int i = 0; i < 3; i++) { g(q); int t = i + m + 1; if (q2 > i) cq_phi(0.2 * t); } return cq_measure(q) + cq_measure(q2); }
