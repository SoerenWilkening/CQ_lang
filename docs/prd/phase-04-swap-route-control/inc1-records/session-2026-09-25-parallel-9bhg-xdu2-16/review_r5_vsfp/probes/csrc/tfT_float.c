#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); float q = cq_theta((float)(m & 7), .5); float p = q * 3; int r = m + 1; return r + (int)cq_measure(p) + (int)cq_measure(q); }
