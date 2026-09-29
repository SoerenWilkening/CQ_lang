#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int t = q / 4; int r; if (t == s) r = cq_theta(t, .9); else r = cq_theta(s, .3); return cq_measure(r) + cq_measure(t); }
