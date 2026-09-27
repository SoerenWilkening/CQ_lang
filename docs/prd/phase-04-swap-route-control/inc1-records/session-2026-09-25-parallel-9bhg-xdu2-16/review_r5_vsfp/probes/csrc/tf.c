#include <stdlib.h>
int h(float a, int k);
int main(int c, char **v) { int m = atoi(v[1]); float q = cq_theta((float)(m & 7), .5); float p = q * 3; int r = h(p, m); return r + (int)cq_measure(p) + (int)cq_measure(q); }
