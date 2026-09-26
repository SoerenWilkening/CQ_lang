#include <stdlib.h>
long double hw(long double a, long double k);
__attribute__((noinline)) long double fw(long double m) { long double q = cq_theta(m, .5); return hw(q, m); }
int main(int argc, char **argv) { long double m = (long double)atoi(argv[1]); long double n = (long double)atoi(argv[2]); long double q2 = cq_theta(n, .25); long double u = q2 + fw(m); return (int)cq_measure(u); }
