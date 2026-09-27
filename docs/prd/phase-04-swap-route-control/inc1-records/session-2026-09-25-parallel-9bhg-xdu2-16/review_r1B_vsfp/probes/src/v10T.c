#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = 0; for (int i = 0; i < 3; i++) { t += i + 1; q = cq_theta(q, .1); } return t + cq_measure(q); }
