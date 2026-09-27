#include <stdlib.h>
int hd(long double a, int k);
int main(int c, char **v) { int m = atoi(v[1]); long double x = cq_theta((long double)(m & 7), .5); int r = hd(x, m); x = cq_theta(x, .7); return r + (int)cq_measure(x); }
