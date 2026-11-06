#include <setjmp.h>
jmp_buf jb; int g;
int f(int a,int c){
  cq_theta(&a, 1.0);
  int x=a+1;
  if(!setjmp(jb)){ g=x; if(c>0) longjmp(jb,1); g=x*2; }
  else { g=x+5; }
  return cq_measure(g);
}
