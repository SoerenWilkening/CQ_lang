#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; volatile int z = p * 3; int t = m + 1; b = cq_theta(b, .7); return t + cq_measure(b); }
