#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .4); if (q > 5) { g(q); q2 = cq_theta(q2, (n + 1) * 0.1); } return cq_measure(q2) + cq_measure(q); }
