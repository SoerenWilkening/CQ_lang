#include <stdlib.h>
static int REG[4] = {1, 2, 3, 4};
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 3, .5); int x = REG[q & 3]; return cq_measure(x) + cq_measure(q); }
