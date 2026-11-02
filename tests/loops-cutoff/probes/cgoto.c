/* tests/loops-cutoff computed-goto probes (cq-8i5g, CR rule 13 ruling 2026-11-02): a computed goto inside a K-loop
 * trip is a switch over its destination list, its scrutinee the integer the address was derived from (a constant
 * blockaddress table read at an index). Each entry is checked §6 against its own C program (cqcheck user).
 * Regenerate cgoto.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec cgoto.c -o cgoto.O1.ll */
#include "CQ.h"
/* A classical index (the induction's parity) chooses the arm. */
int cg_classical(int x0, double th) {
  static const void *tbl[] = {&&even, &&odd};
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  while ((x >> i) & 1) {
    goto *tbl[i & 1];
  even:
    acc = acc * 3 + 1; i++; continue;
  odd:
    acc = acc + 7; i++; continue;
  }
  return cq_measure(acc);
}
/* A quantum index (a bit of x) chooses the arm. */
int cg_quantum(int x0, double th) {
  static const void *tbl[] = {&&zero, &&one};
  int x = x0; cq_theta(&x, th);
  int acc = 1, i = 0;
  do {
    goto *tbl[(x >> (i + 4)) & 1];
  zero:
    acc = acc * 5; i++; continue;
  one:
    acc = acc + 3; i++; continue;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
