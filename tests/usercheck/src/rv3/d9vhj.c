#include <stdlib.h>
int g;
__attribute__((noinline)) int fa(int x){ g+=1; return x+1; }
int f(int a,int b,int c){
  cq_theta(&a, 1.0); cq_theta(&b, 1.0);
  int (*fp)(int)= (a&1)?abs:fa;
  int (*fc)(int)= c>0?abs:fa;
  int r=fp(b); int s=0;
  if(b&1) s=fc(a);
  return cq_measure(r)+3*cq_measure(s)+5*cq_measure(g);
}
