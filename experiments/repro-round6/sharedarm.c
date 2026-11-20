/* cq-fi2wc (GLPK read_char, reduced): a K-loop whose noreturn arm (the error call) is entered both from a trip and from
   the code after the loop, where the exits meet past an error branch. With the exits given their continuation, the code
   after the loop runs once after it (its exit edges meet at a hub); the error block it shares with the loop's own noreturn
   arm then needs a copy of its own, or the trip's lowering reads the hub's edge index before the loop has run. */
#include <stdlib.h>
unsigned char buf[8] = {65, 13, 66, 32, 10, 120, 13, 10};
int mode = 7;
static void __attribute__((noinline, noreturn)) fail(int c) { exit(c & 7); }
int sharedarm(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned i = x & 7;
  int c;
  for (;;) {
    c = buf[i & 7];
    if (c == 10)
      break;
    if (buf[(i + 1) & 7] == mode)
      goto err;
    if (c == 13) {
      i++;
      continue;
    }
    if (c == 32)
      break;
    if (c > 100)
      goto err;
    mode++;
    break;
  }
  return c * 2 + (int)i;
err:
  fail(c);
}
