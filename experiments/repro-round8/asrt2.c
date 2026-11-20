/* r8: an assertion of two quantum conditions (one arm block, two edges into it, glp_assert_ style with arguments) and
   output after it in the trip. */
#include <stdio.h>
void my_assert(const char *e, int line) __attribute__((noreturn));
#define xassert(c) ((void)((c) || (my_assert(#c, __LINE__), 1)))
int asrt2(unsigned x0, double th, unsigned y)
{
  unsigned x = x0;
  cq_theta(&x, th);
  x &= 63;
  int s = 0;
  while (x > 1) {
    xassert(x != 12 && (x & 3) != 3);
    printf("t %u\n", x & 1);
    s += (int)(x & y);
    x = (x & 1) ? x - 1 : x >> 1;
  }
  return s;
}
