/* tests/calls probe, cq-ojgho (rule 16): a <wchar.h> stream call by name is the host boundary although the module has
   its body (as the musl bundle has fputwc's): the body is never lifted for the call, which is rule 16's effect entry. */
#include <stdio.h>
#include <wchar.h>
__attribute__((noinline)) wint_t fputwc(wchar_t c, FILE *f) {
  return fputc((int)c, f) == EOF ? WEOF : (wint_t)c;
}
__attribute__((noinline)) static int show(signed char x) {
  if (x & 1)
    fputwc(L'a' + (x & 7), stdout);
  return x + 1;
}
int stream_wide_body(signed char x0) {
  signed char x = x0;
  cq_theta(&x, 0.3);
  int r = show(x);
  return cq_measure(r);
}
