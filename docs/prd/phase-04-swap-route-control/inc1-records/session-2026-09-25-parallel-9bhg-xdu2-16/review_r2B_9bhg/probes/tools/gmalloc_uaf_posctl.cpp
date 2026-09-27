#include <cstdio>
#include <vector>
int main(){int *v=new int[3]; v[1]=5; delete[] v; volatile int x=v[1]; printf("%d\n", x); return 0;}
