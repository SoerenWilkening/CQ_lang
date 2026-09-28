#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int acc = 0; for (int k = 0; k < 3; k++) { int q = cq_theta(m, .5); int r = s + k; if (q > k) r = cq_theta(s + k, .2); acc += cq_measure(r); } return acc; }
