#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]), s0 = atoi(v[2]); int acc = 0; int s = s0;
 { int q = cq_theta(m + 0, .5); int r = s; if (q > 3) r = cq_theta(s, .2); acc += cq_measure(r); s = s * 2 + 1; }
 { int q = cq_theta(m + 1, .5); int r = s; if (q > 3) r = cq_theta(s, .2); acc += cq_measure(r); s = s * 2 + 1; }
 { int q = cq_theta(m + 2, .5); int r = s; if (q > 3) r = cq_theta(s, .2); acc += cq_measure(r); s = s * 2 + 1; }
 return acc; }
