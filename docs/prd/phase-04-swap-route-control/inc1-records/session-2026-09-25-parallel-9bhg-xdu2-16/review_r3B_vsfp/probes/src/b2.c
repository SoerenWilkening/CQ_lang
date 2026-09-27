#include <stdlib.h>
static volatile double A = 0.5;
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = cq_theta(m & 3, .2); double a = (q > 3) ? A : 0.9; p = cq_theta(p, a); return cq_measure(p) + cq_measure(q); }
