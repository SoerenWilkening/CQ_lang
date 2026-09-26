#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); _Bool b2 = cq_theta((_Bool)(m & 2), .6); int x = cq_theta(m & 7, .5); int r = b ? x : 7; int t = m + 1; int s = b2 ? r : 3; return t + cq_measure(s); }
