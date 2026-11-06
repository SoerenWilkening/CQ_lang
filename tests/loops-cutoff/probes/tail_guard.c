/* tests/loops-cutoff probe (CR rules 9, 14): musl stpcpy's word loop, a quantum-exit loop of the tail of the alignment loop. Its
 * pre-header guard's false edge goes straight into the byte copy, whose pointers are a phi over that skip, the word loop's exit
 * and a classical skip of both: where the first word holds the NUL, the byte copy runs at the start, not at address 0.
 * Regenerate tail_guard.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec tail_guard.c -o tail_guard.O1.ll */
#include "CQ.h"
#define ONES ((unsigned long)-1 / 255)
#define HIGHS (ONES * 128)
#define HASZERO(x) (((x) - ONES) & ~(x) & HIGHS)
__attribute__((noinline)) static char *tg_copy(char *d, const char *s) {
  if ((((unsigned long)s ^ (unsigned long)d) & 7) == 0) {
    for (; (unsigned long)s & 7; s++, d++)
      if (!(*d = *s))
        return d;
    unsigned long *wd = (void *)d;
    const unsigned long *ws = (const void *)s;
    for (; !HASZERO(*ws); wd++, ws++)
      *wd = *ws;
    d = (void *)wd;
    s = (const void *)ws;
  }
  for (; (*d = *s); s++, d++)
    ;
  return d;
}
/* the destination's first byte quantum: the copy overwrites it with the classical source's */
int tg_dst(char de, char se, double th) {
  char d[32] __attribute__((aligned(16))) = {0}, s[32] __attribute__((aligned(16))) = {0};
  for (int j = 0; j < 11; j++) d[j + 1] = s[j + 1] = 'a' + j;
  d[0] = de;
  s[0] = se;
  cq_theta(&d[0], th);
  tg_copy(d, s);
  return cq_measure(d[0]);
}
/* the source's first byte quantum: the guard, the word loop and the byte copy all read it */
int tg_src(char de, char se, double th) {
  char d[32] __attribute__((aligned(16))) = {0}, s[32] __attribute__((aligned(16))) = {0};
  for (int j = 0; j < 11; j++) d[j + 1] = s[j + 1] = 'a' + j;
  d[0] = de;
  s[0] = se;
  cq_theta(&s[0], th);
  tg_copy(d, s);
  char r = cq_measure(d[0]);
  return r + cq_measure(d[3]);
}
