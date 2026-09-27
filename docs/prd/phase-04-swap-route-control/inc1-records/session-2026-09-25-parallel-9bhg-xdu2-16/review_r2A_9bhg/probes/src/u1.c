#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; b = cq_theta(b, .7); return cq_measure(b) + cq_measure(p); }
