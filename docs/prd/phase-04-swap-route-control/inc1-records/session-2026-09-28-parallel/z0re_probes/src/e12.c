#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); _Bool s = atoi(v[2]) & 1; int q = cq_theta(m, .5); _Bool r = s; if (q > 3) r = cq_theta(s, .2); return cq_measure(r) + cq_measure(q); }
