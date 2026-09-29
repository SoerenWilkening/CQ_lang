#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); double s = atof(v[2]); int q = cq_theta(m, .5); double r = s; if (q > 3) r = cq_theta(s, .2); return (int)cq_measure(r) + cq_measure(q); }
