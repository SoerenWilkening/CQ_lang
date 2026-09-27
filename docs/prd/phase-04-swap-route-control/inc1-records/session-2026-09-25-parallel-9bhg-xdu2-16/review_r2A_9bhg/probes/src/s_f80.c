#include <stdlib.h>
long double hd(long double a, long double k); long double g2d(long double a, long double b);
int main(int argc, char **argv) { long double m = (long double)atoi(argv[1]); long double n = (long double)atoi(argv[2]); long double q = cq_theta(m, .5); long double q2 = cq_theta(n, .25); long double t1 = hd(q, m); long double t2 = hd(m, q2); long double u = g2d(t1, t2); return (int)cq_measure(u); }
