/* GLPK _glp_mpl_* (reduced): setjmp on a jmp_buf at a quantum address, in a callee whose result needs its twin. */
#include <setjmp.h>
struct S { int x; jmp_buf b; };
struct S tab[2];
__attribute__((noinline)) static int g(struct S *p)
{
  if (setjmp(p->b))
    return 1;
  return p->x;
}
int f(unsigned k0, double th)
{
  unsigned k = k0;
  cq_theta(&k, th);
  return g(&tab[k & 1]) + 1;
}
