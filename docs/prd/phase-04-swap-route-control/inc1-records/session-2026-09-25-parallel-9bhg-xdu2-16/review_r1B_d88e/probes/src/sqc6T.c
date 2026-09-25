#include <stdlib.h>
int main(int c, char **v) { signed char m = (signed char)atoi(v[1]); int m2 = atoi(v[2]); signed char q = cq_theta(m, .5); signed char t = (signed char)(m+1); int acc = 0; for (int i = 0; i < m2; i++) { signed char r = t; if ((i & 1) == 0) r = cq_theta(t, .2); acc += (int)cq_measure(r); } return acc; }
