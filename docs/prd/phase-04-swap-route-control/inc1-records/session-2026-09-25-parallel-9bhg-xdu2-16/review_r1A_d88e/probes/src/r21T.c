#include <stdlib.h>
#include <stdio.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = m + 1; int r = q; if (m > 3) r = cq_theta(q, .2); printf("%d", r); return t; }
