#include <stdlib.h>
long double hd(long double a, long double k);
__attribute__((noinline)) long double f(long double m) { long double q = cq_theta(m, .5); return hd(q, m); }
int main(int c, char **v) { long double m = atoi(v[1]); long double r = f(m); if (r > 3) cq_phi(.3); long double q2 = cq_theta(m, .2); return (int)cq_measure(q2) + (int)r; }
