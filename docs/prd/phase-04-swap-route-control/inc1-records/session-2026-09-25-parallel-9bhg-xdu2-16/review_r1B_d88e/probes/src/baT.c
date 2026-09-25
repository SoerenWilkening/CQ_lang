#include <stdlib.h>
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int b[4]; for (int i=0;i<4;i++) b[i] = (n > 2) ? (i+1) : cq_theta(i,.1); int s=0; for (int i=0;i<4;i++) s += cq_measure(b[i]); return s; }
