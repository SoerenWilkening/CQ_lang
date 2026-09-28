#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); signed char s = atoi(v[2]); int q = cq_theta(m, .5); signed char r = s; if (q > 3) r = cq_theta(s, .2); return cq_measure(r) + cq_measure(q); }
