#include <stdlib.h>
signed char h(signed char a, signed char k);
int main(int c, char **v) { signed char m = (signed char)atoi(v[1]); int m2 = atoi(v[2]); signed char q = cq_theta(m, .5); signed char t = h(q, m); signed char r = t; switch (m2) { case 1: r = cq_theta(t, .1); break; case 4: r = cq_theta(t, .4); break; case 7: r = cq_theta(t, .7); break; } return (int)cq_measure(r); }
