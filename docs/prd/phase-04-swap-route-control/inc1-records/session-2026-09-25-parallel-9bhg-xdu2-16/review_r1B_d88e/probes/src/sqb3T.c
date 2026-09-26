#include <stdlib.h>
int main(int c, char **v) { _Bool m = (atoi(v[1])&1); int m2 = atoi(v[2]); _Bool q = cq_theta(m, .5); _Bool t = !m; _Bool r = t; int x = 0; if (m2 > 3) r = cq_theta(t, .2); else x = (int)cq_measure(t); return (int)cq_measure(r) + x; }
