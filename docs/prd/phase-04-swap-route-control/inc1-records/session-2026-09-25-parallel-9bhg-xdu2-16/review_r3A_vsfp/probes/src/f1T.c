#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); double z = cq_theta(1.5, .3); double x = cq_theta((double)(m & 7), .5); double y = x * 2.0; int r = m + 1; double w = cq_measure(y); return r + (int)w + (int)cq_measure(x) + (int)cq_measure(z); }
