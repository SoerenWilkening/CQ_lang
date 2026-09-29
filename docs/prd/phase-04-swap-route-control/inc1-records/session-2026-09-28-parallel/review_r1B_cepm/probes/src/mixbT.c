#include <stdlib.h>
void g(int a);
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]); int q = cq_theta(m, .5); int b[2]; b[0] = q; g(q); b[1] = m + 1; int s = cq_measure(b[n & 1]); return s + cq_measure(q); }
