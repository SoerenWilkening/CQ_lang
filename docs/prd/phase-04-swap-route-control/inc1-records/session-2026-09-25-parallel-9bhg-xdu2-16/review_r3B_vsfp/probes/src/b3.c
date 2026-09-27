#include <stdlib.h>
static volatile double A = 0.5;
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); double a = (q > 3) ? A : 0.9; cq_phi(a); q = cq_theta(q, .7); return cq_measure(q); }
