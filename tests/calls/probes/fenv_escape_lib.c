/* tests/calls probe (cq-4e6m): compiled under FENV_ACCESS ON. */
#include <setjmp.h>
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
extern jmp_buf fe_jb;
__attribute__((noinline)) int fe_inner(double q, double k) {
  if (q * 0.5 > k) longjmp(fe_jb, 1);   /* strict fmul and fcmp before the escape decision */
  return 7;   /* nothing raising after the escape decision (cq-jwdf) */
}
