#include <fenv.h>
#include <stdlib.h>
char buf[16] = "abcdefghijklmno";
__attribute__((noinline)) int g(int x) { feraiseexcept(FE_INEXACT); return x; }
// A classically bounded loop with a quantum exit whose noreturn arm (lowered in each trip) changes the flags.
int e(void) {
  char n = 0;
  cq_theta(&n, .5);
  unsigned i = 0;
  for (;;) {
    if (buf[i] == n) break;
    i++;
    if (i == 7) { g(n); exit(3); }
  }
  return cq_measure(i) + fetestexcept(FE_INEXACT);
}
// The same with the flags a rail before the loop.
int eq(void) {
  char n = 0;
  cq_theta(&n, .5);
  if (n & 1) feraiseexcept(FE_UNDERFLOW);
  unsigned i = 0;
  for (;;) {
    if (buf[i] == n) break;
    i++;
    if (i == 7) { g(n); exit(3); }
  }
  return cq_measure(i) + fetestexcept(FE_INEXACT | FE_UNDERFLOW);
}
// A loop with no live exit (both exits into the noreturn arm, lowered in each trip), in a _ctl clone with the flags a rail
// (TinyCC's parse_operand, cq-6zudr).
__attribute__((noinline)) unsigned h2(int n) {
  if (n & 1) feraiseexcept(FE_UNDERFLOW);
  if (n > 2) {
    unsigned i = 0;
    while (buf[i] != n) i++;
    g(i);
    exit(3);
  }
  return n + fetestexcept(FE_INEXACT | FE_UNDERFLOW);
}
int en(void) {
  char n = 0;
  cq_theta(&n, .5);
  unsigned r = 0;
  if (n & 4) r = h2(n);
  return cq_measure(r) + fetestexcept(FE_INEXACT | FE_UNDERFLOW);
}
// The loop in a _ctl clone, the flags a rail at its entry.
__attribute__((noinline)) unsigned h(int n) {
  unsigned i = 0;
  for (;;) {
    if (buf[i] == n) break;
    i++;
    if (i == 7) { g(n); exit(3); }
  }
  return i;
}
int ec(void) {
  char n = 0;
  cq_theta(&n, .5);
  unsigned r = 0;
  if (n & 1) { feraiseexcept(FE_UNDERFLOW); r = h(n); }
  return cq_measure(r) + fetestexcept(FE_INEXACT | FE_UNDERFLOW);
}
