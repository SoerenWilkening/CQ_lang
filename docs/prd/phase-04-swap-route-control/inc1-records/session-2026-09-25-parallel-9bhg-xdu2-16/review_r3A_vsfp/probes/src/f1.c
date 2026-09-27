#include <stdlib.h>
int hd(double a, int k);
int main(int c, char **v) { int m = atoi(v[1]); double z = cq_theta(1.5, .3); double x = cq_theta((double)(m & 7), .5); double y = x * 2.0; int r = hd(y, m); double w = cq_measure(y); return r + (int)w + (int)cq_measure(x) + (int)cq_measure(z); }
