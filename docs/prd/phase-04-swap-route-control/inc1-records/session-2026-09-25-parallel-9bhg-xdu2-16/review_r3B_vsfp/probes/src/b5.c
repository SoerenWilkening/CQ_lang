#include <stdlib.h>
static volatile _Bool KB = 1;
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); _Bool r = (q > 3) ? KB : 0; int mr = cq_measure(r); q = cq_theta(q, .7); return mr + cq_measure(q); }
