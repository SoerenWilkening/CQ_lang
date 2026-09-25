#include <stdlib.h>
int main(int c, char **v) { short m = (short)atoi(v[1]); int m2 = atoi(v[2]); short q = cq_theta(m, .5); short t = (short)(m+1); int acc = 0; for (int i = 0; i < m2; i++) { short r = t; if ((i & 1) == 0) r = cq_theta(t, .2); acc += (int)cq_measure(r); } return acc; }
