#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r; switch (q) { case 1: r = 4; break; case 2: r = 6; break; default: r = 9; } return cq_measure(r) + cq_measure(q); }
