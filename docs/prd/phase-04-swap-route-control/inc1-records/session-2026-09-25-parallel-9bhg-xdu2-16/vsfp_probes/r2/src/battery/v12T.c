#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int t = m + 1; return t + cq_measure(b); }
