#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); signed char q = cq_theta((signed char)(m & 7), .5); signed char p = q ^ (signed char)1; int r = m + 1; int s = (int)cq_measure(p); q = cq_theta(q, .7); return r + s + (int)cq_measure(q); }
