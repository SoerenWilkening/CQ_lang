#include <stdlib.h>
long double hd(long double a, long double k);
__attribute__((noinline)) long double f(long double m) { long double q = cq_theta(m, .5); return hd(q, m); }
int main(int c, char **v) { long double m = atoi(v[1]); long double r = f(m); return (int)cq_measure(r); }
