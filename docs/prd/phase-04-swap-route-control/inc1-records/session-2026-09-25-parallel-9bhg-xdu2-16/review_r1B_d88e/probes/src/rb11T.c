#include <stdlib.h>
#include <stdio.h>
int main(int c, char **v) { int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=(m+1); int acc=0; for (int i=0;i<n;i++) acc+=t; return cq_measure(q)+acc; }
