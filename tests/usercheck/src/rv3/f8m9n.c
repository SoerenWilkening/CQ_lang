#include <fenv.h>
#pragma STDC FENV_ACCESS ON
int f(int a,int b){
  cq_theta(&a, 1.0); cq_theta(&b, 1.0);
  feclearexcept(FE_ALL_EXCEPT);
  if(a&1) feraiseexcept(FE_INEXACT);
  if(b&1) fesetround(FE_UPWARD);
  int r=fetestexcept(FE_INEXACT);
  int m=fegetround();
  return cq_measure(r)+cq_measure(m)*3;
}
