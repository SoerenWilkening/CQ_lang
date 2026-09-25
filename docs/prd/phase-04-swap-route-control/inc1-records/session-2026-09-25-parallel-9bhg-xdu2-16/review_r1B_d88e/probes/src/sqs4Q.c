#include <stdlib.h>
short h(short a, short k);
int main(int c, char **v) { short m = (short)atoi(v[1]); int m2 = atoi(v[2]); short q = cq_theta(m, .5); short t = h(q, m); short r = t; if (m2 > 3) r = cq_theta(t, .2); short s = r; if (m2 > 5) s = cq_theta(r, .4); return (int)cq_measure(s); }
