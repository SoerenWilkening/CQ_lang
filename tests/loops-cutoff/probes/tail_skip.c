/* tests/loops-cutoff probe (CR rules 5, 9, 14): musl stpcpy's body, under a quantum predicate. The byte loop's tail holds the word loop,
 * whose first test may skip it (the first word holds the zero), and the block after it reads the skipped path's pointers: on the
 * tail's paths the skip edge lies outside the assumption of the word loop's header.
 * Regenerate tail_skip.O1.ll:
 * clang -O1 -fno-builtin -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec tail_skip.c -o tail_skip.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static char *cp(char *restrict d, const char *restrict s) {
  typedef unsigned long __attribute__((__may_alias__)) word;
  word *wd;
  const word *ws;
  if ((unsigned long)s % 8 == (unsigned long)d % 8) {
    for (; (unsigned long)s % 8; s++, d++)
      if (!(*d = *s))
        return d;
    wd = (void *)d;
    ws = (const void *)s;
    for (; !((*ws - 0x0101010101010101UL) & ~*ws & 0x8080808080808080UL); *wd++ = *ws++)
      ;
    d = (void *)wd;
    s = (const void *)ws;
  }
  for (; (*d = *s); s++, d++)
    ;
  return d;
}
int ts_copy(char x0, char x1, long at) {
  char d[64] __attribute__((aligned(16))) = {0}, s[64] __attribute__((aligned(16))) = {0};
  for (int j = 0; j < 11; j++)
    s[j + 1] = "12.5e3 Ab,x"[j];
  d[0] = x0;
  s[0] = x1;
  cq_theta(&d[0], 0.3);
  if (d[1] == 0)
    cp(d, s + 0 * at);
  return cq_measure(d[0]);
}
