#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int t = m + 1; q = cq_theta(q, .7); return t + cq_measure(q); }
