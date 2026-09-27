#include <stdlib.h>
int main(int c, char **v) { int n = atoi(v[2]); int q2 = cq_theta(n, .3); int p = (q2 > 3) ? 9 : 4; q2 = cq_theta(q2, .7); return cq_measure(q2) + cq_measure(p); }
