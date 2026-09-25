#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int m2 = atoi(v[2]); int q = cq_theta(m, .5); int t = (m+1); int acc = 0; for (int i = 0; i < m2; i++) { int r = t; if ((i & 1) == 0) r = cq_theta(t, .2); acc += (int)cq_measure(r); } return acc; }
