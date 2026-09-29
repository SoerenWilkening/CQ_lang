#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int r = s; if (q == s + 1) r = cq_theta(s, .2); return cq_measure(r) + cq_measure(q); }
