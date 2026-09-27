#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int t = (q > 3) ? 1 : 0; int r = 0; if (t) { r = q * 3; } return cq_measure(r) + cq_measure(q); }
