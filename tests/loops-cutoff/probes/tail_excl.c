/* tests/loops-cutoff probe (CR rules 9, 14): musl strlen's body. The byte loop's exit enters a tail (word loop, then byte loop) that the
 * aligned path enters directly. On the aligned path, which excludes the unit, the continuation's phi is the tail's incoming: no join arm
 * covers it.
 * Regenerate tail_excl.O1.ll:
 * clang -O1 -fno-builtin -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec tail_excl.c -o tail_excl.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static unsigned long len(const char *s) {
  const char *a = s;
  typedef unsigned long __attribute__((__may_alias__)) word;
  const word *w;
  for (; (unsigned long)s % 8; s++)
    if (!*s)
      return s - a;
  for (w = (const void *)s; !((*w - 0x0101010101010101UL) & ~*w & 0x8080808080808080UL); w++)
    ;
  s = (const void *)w;
  for (; *s; s++)
    ;
  return s - a;
}
long te_len(char x0, long at) {
  char b[64] __attribute__((aligned(16))) = {0};
  for (int j = 0; j < 11; j++)
    b[j + 1] = "12.5e3 Ab,x"[j];
  b[0] = x0;
  cq_theta(&b[0], 0.3);
  return cq_measure((long)len(b + (at & 1)));
}
