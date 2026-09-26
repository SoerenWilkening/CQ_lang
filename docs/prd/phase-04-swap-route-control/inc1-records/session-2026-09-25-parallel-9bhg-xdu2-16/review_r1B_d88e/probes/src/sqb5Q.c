#include <stdlib.h>
_Bool h(_Bool a, _Bool k);
int main(int c, char **v) { _Bool m = (atoi(v[1])&1); int m2 = atoi(v[2]); _Bool q = cq_theta(m, .5); _Bool t = h(q, m); _Bool r = t; switch (m2) { case 1: r = cq_theta(t, .1); break; case 4: r = cq_theta(t, .4); break; case 7: r = cq_theta(t, .7); break; } return (int)cq_measure(r); }
