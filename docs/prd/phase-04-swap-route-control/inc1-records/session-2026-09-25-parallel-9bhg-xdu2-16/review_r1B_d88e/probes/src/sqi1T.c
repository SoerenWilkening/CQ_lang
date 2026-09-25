#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int m2 = atoi(v[2]); int q = cq_theta(m, .5); int t = (m+1); int r = t; if (m2 > 3) r = cq_theta(t, .2); return (int)cq_measure(r); }
