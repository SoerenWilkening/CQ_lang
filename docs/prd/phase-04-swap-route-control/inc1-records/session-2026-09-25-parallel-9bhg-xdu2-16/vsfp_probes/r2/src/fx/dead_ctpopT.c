#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); unsigned q = cq_theta((unsigned)(m & 255), .5); int t = m + 1; q = cq_theta(q, .7); return t + cq_measure(q); }
