#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); double z = cq_theta(1.5, .3); double x = cq_theta((double)(m & 7), .5); double y = x * 2.0; double r = x * 3.0; double w = cq_measure(y); return (int)cq_measure(r) + (int)w + (int)cq_measure(z); }
