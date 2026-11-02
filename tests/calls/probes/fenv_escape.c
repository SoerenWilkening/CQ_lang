/* tests/calls probe (cq-4e6m; CR rules 23, 24; 82 with 101): a clone carrying the floating-point environment
 * (FENV_ACCESS ON: a strict op on the quantum value) that escapes by longjmp under a quantum predicate:
 * {result, flags, escaped}. The caller has no fenv state (mode 0, an empty flags rail).
 * Regenerate: clang -O1 fenv_escape.c; clang -O1 fenv_escape_lib.c; llvm-link -S both -o fenv_escape.O1.ll */
#include "CQ.h"
#include <setjmp.h>
extern jmp_buf fe_jb;
int fe_inner(double q, double k);
jmp_buf fe_jb;
int fe_escape(double x0, double th, double k) {
  double x = x0;
  cq_theta(&x, th);
  int r;
  if (setjmp(fe_jb) == 0)
    r = fe_inner(x, k) + 2;
  else
    r = -1;
  return cq_measure(r);
}
