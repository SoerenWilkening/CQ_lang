#include <stdlib.h>
int ident(int a);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r = ident(q); return r + cq_measure(q); }
