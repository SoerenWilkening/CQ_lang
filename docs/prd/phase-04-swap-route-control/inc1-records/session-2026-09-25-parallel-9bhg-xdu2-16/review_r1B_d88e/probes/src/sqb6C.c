#include <stdlib.h>
_Bool h(_Bool a, _Bool k);
int main(int c, char **v) { _Bool m = (atoi(v[1])&1); int m2 = atoi(v[2]); _Bool q = cq_theta(m, .5); _Bool t = h(q, m); int acc = 0; for (int i = 0; i < m2; i++) { _Bool r = t; if ((i & 1) == 0) r = cq_theta(t, .2); acc += (int)cq_measure(r); } return acc; }
