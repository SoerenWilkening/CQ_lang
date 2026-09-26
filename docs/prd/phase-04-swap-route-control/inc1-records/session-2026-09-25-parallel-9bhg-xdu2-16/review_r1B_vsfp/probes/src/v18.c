#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int t = 0; for (int i = 0; i < m; i++) { int r = cq_theta(i, .3); t += h(r, i); t += cq_measure(r); } return t; }
