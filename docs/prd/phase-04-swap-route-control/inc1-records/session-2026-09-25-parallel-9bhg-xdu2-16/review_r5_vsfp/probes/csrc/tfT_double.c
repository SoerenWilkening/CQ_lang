#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); double q = cq_theta((double)(m & 7), .5); double p = q * 3; int r = m + 1; return r + (int)cq_measure(p) + (int)cq_measure(q); }
