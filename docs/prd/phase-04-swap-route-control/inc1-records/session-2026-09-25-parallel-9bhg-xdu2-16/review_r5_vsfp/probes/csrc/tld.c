#include <stdlib.h>
int h(long double a, int k);
int main(int c, char **v) { int m = atoi(v[1]); long double q = cq_theta((long double)(m & 7), .5); long double p = q * 3; int r = h(p, m); return r + (int)cq_measure(p) + (int)cq_measure(q); }
