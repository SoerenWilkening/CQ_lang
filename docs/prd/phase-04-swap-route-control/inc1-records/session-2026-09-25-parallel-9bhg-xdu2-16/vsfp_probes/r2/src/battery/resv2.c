#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); double th = atof(v[2]); int q = cq_theta(m & 7, th); return cq_measure(q); }
