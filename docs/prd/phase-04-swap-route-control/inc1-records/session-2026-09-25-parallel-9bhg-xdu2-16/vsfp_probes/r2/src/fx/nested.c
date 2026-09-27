#include <stdlib.h>
int out3(int a, int b);
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int t = out3(p, m); b = cq_theta(b, .7); return t + cq_measure(b); }
