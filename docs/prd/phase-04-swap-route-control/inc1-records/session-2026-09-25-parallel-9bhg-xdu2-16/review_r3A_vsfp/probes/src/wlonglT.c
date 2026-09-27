#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); long long q = cq_theta((long long)(m & 7), .5); long long p = q ^ (long long)1; int r = m + 1; int s = (int)cq_measure(p); q = cq_theta(q, .7); return r + s + (int)cq_measure(q); }
