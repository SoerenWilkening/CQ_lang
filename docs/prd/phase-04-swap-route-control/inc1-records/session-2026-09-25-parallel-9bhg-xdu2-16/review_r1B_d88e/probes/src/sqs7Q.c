#include <stdlib.h>
short h(short a, short k);
int main(int c, char **v) { short m = (short)atoi(v[1]); int m2 = atoi(v[2]); short q = cq_theta(m, .5); short t = h(q, m); short r = t; if (m2 > 3) r = cq_theta(t, .2); return (int)cq_measure(r) + (int)cq_measure(q); }
