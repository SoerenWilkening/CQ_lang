#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); long double q = cq_theta((long double)(m & 7), .5); long double p = q * 3; int r = m + 1; return r + (int)cq_measure(p) + (int)cq_measure(q); }
