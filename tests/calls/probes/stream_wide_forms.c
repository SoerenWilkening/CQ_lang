/* tests/calls probe, cq-83c9c (rule 16, BACKEND_ABI §1.11): the wide printing family, fwprintf and wprintf and their v forms
   through a variadic wrapper, with a quantum argument. Each call is an effect entry whose format is a wchar_t string; the
   evaluator performs one on stdout as stdout text (the host's swprintf per conversion, wcrtomb per character) and one on
   stderr as text neither side compares. */
#include <stdarg.h>
#include <stdio.h>
#include <wchar.h>
__attribute__((noinline)) static void wsay(const wchar_t *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vwprintf(fmt, ap);
  va_end(ap);
}
__attribute__((noinline)) static void wsay_to(FILE *f, const wchar_t *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  vfwprintf(f, fmt, ap);
  va_end(ap);
}
int stream_wide_forms(signed char x0) {
  signed char x = x0;
  cq_theta(&x, 0.3);
  wprintf(L"[%d %ls %s]", x, L"wide", "narrow");
  fwprintf(stdout, L"<%5.1f %lc>", x * 0.25, (wint_t)(L'a' + (x & 7)));
  wsay(L"%d|%4.2ls|%%|", x, L"wxyz");
  wsay_to(stdout, L"{%ld %c %Lg %*d}", (long)x * 3, 'A' + (x & 7), (long double)x / 4, 4, x);
  if (x & 1)
    wsay_to(stdout, L"odd %hhx;", x);
  wsay_to(stderr, L"err %d\n", x);
  fwprintf(stderr, L"err2 %d\n", x);
  return cq_measure(x + 1);
}
