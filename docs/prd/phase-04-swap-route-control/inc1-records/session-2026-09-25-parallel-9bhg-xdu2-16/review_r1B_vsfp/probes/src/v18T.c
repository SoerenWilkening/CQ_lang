#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int t = 0; for (int i = 0; i < m; i++) { int r = cq_theta(i, .3); t += i + 1; t += cq_measure(r); } return t; }
