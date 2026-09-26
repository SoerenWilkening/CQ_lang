#include <stdlib.h>
short h(short a, short k);
int main(int c, char **v) { short m = (short)atoi(v[1]); int m2 = atoi(v[2]); short q = cq_theta(m, .5); short t = h(q, m); short r = t; int x = 0; if (m2 > 3) r = cq_theta(t, .2); else x = (int)cq_measure(t); return (int)cq_measure(r) + x; }
