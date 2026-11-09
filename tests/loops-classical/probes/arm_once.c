/* cq-os2bx (owner 2026-11-09, Q1; CR rules 3, 14): musl __fwritex's shape. A case-3 loop (classical bound l, a quantum
 * exit on a bus load) whose exit arm calls a function and stores: the arm runs ONCE after the loop, its loop values
 * (the exit index i) the select chain over the exit flags, never once per trip. Each entry is checked §6 against its
 * own C program. Regenerate arm_once.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec arm_once.c -o arm_once.O1.ll */
#include "CQ.h"
struct sink { unsigned char *wpos; int n; int (*write)(struct sink *, const unsigned char *, int); };
__attribute__((noinline)) static int sink_write(struct sink *f, const unsigned char *s, int l) {
  for (int k = 0; k < l; k++) f->wpos[k] = s[k];
  f->wpos += l;
  f->n += l;
  return l;
}
__attribute__((noinline)) static int fwritex(const unsigned char *s, int l, struct sink *f) {
  int i;
  for (i = l; i && s[i - 1] != '\n'; i--);
  if (i) {
    int n = f->write(f, s, i);
    if (n < i) return n;
    s += i;
    l -= i;
  }
  for (int k = 0; k < l; k++) f->wpos[k] = s[k];
  f->wpos += l;
  return l + i;
}
int ao_write(unsigned char c0, double th) {
  unsigned char s[4] = {'a', 'b', 'c', 'd'};
  unsigned char c = c0;
  cq_theta(&c, th);
  s[1] = c;                                   /* a quantum char: '\n' or not */
  unsigned char out[8] = {0};
  struct sink f = {out, 0, sink_write};
  int r = fwritex(s, 4, &f);
  return cq_measure(r + 16 * f.n + 64 * (out[0] + out[1] + out[2] + out[3]));
}
