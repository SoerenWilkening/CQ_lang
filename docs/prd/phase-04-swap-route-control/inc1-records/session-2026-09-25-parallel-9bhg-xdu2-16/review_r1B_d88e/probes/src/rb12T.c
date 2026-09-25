#include <stdlib.h>
#include <stdio.h>
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=(m+1); int x=t; while (x>>1) { x>>=1; n++; } return cq_measure(q)+n; }
