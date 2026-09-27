#include <stdlib.h>
int hd(float a, int k);
int main(int c, char **v) { int m = atoi(v[1]); float x = cq_theta((float)(m & 7), .5); int r = hd(x, m); x = cq_theta(x, .7); return r + (int)cq_measure(x); }
