/* tests/calls probe, cq-83c9c (rule 16, BACKEND_ABI §1.11): vprintf and vfprintf are stream calls, so their calls are effect
   entries whose last field is the va_list's address. A variadic wrapper with a quantum argument fills the va_list on the bus
   (rule 16's variadic calls); the evaluator performs a vprintf or vfprintf entry on stdout as stdout text, reading the
   va_list and the arguments it points to through the bus, and one on stderr as text neither side compares. */
#include <stdarg.h>
#include <stdio.h>
__attribute__((noinline)) static void say(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vprintf(fmt, ap);
  va_end(ap);
}
__attribute__((noinline)) static void say_to(FILE *f, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vfprintf(f, fmt, ap);
  va_end(ap);
}
int stream_vforms(signed char x0) {
  signed char x = x0;
  cq_theta(&x, 0.3);
  say("%d|%s|%5.3s|", x, "ab", "wxyz");
  say_to(stdout, "<%ld %c %.2f %Lg %*d>", (long)x * 3, 'A' + (x & 7), x * 0.5, (long double)x / 4, 4, x);
  if (x & 1)
    say_to(stdout, "odd %hhx;", x);
  say_to(stderr, "err %d\n", x);
  return cq_measure(x + 1);
}
