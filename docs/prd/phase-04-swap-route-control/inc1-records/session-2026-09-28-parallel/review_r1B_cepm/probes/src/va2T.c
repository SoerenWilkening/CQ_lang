#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(n, .4); int y = 0; if (q > 5) { g(q2); y = m + 1; } return cq_measure(y) + cq_measure(q) + cq_measure(q2); }
