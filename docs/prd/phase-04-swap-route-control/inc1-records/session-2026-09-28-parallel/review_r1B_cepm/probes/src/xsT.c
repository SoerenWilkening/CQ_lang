#include <stdlib.h>
int ext_unknown(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); ext_unknown(q); int t = m + 1; if (t > 3) q = cq_theta(q, .2); return cq_measure(q); }
