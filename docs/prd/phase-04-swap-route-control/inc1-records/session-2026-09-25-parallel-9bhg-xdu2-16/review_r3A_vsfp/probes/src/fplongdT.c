#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); long double x = cq_theta((long double)(m & 7), .5); int r = m + 1; x = cq_theta(x, .7); return r + (int)cq_measure(x); }
