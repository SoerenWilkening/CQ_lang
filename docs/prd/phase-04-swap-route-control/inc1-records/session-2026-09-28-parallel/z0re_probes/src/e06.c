#include <stdlib.h>
int g;
int main(int c, char **v) { g = atoi(v[2]); int m = atoi(v[1]); int q = cq_theta(m, .5); int s = g; int r = s; if (q > 3) r = cq_theta(s, .2); return cq_measure(r) + cq_measure(q); }
