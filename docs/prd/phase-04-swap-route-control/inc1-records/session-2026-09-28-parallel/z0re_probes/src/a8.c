#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r = 5; if (t == 5) r = cq_theta(t, .9); return cq_measure(r) + cq_measure(t); }
