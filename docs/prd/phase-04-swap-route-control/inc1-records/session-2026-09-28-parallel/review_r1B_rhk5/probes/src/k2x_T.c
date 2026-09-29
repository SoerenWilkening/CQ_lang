#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int s = (p * 5) ^ q; q = cq_theta(q, .7); return cq_measure(s) + cq_measure(q); }
