#include <stdlib.h>
signed char h(signed char a, signed char k);
int main(int c, char **v) { signed char m = (signed char)atoi(v[1]); int m2 = atoi(v[2]); signed char q = cq_theta(m, .5); signed char t = h(q, m); signed char r = t; if (m2 > 3) r = cq_theta(t, .2); signed char s = r; if (m2 > 5) s = cq_theta(r, .4); return (int)cq_measure(s); }
