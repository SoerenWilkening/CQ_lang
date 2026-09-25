#include <stdlib.h>
int main(int c, char **v) { signed char m = (signed char)atoi(v[1]); int m2 = atoi(v[2]); signed char q = cq_theta(m, .5); signed char t = (signed char)(m+1); signed char r = t; if (m2 > 3) r = cq_theta(t, .2); return (int)cq_measure(r); }
