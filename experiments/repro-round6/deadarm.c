/* cq-fi2wc (GMP pow_equals, reduced): a K-loop with two live exits whose code after the loop holds an ASSERT, a noreturn
   call in a dead end between the exits and their join. LLVM's post-dominators stop at the dead end's `unreachable`, so the
   exits had no common post-dominator: the unit had no continuation and its exit arm ran to the function's end. */
#include <stdlib.h>
unsigned char tab[8] = {5, 3, 7, 1, 6, 2, 0, 4};
int deadarm(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned n = x & 7, i = 0;
  for (;;) {
    if (tab[i] == n)
      return 0;
    i++;
    if (i >= n)
      break;
  }
  if (i > x0 + 5)
    abort();
  return (int)(i * 3 + 1);
}
