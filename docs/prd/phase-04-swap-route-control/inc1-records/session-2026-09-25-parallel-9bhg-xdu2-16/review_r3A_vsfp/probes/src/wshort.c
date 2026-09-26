#include <stdlib.h>
int h(short a, int k);
int main(int c, char **v) { int m = atoi(v[1]); short q = cq_theta((short)(m & 7), .5); short p = q ^ (short)1; int r = h(p, m); int s = (int)cq_measure(p); q = cq_theta(q, .7); return r + s + (int)cq_measure(q); }
