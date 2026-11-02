/* tests/loops-cutoff exit-arm loop probe (cq-8i5g, cq-0dvv; CR rule 14): a K-loop with two live exits whose exit arm
 * (the blocks between one exit and the exits' join) holds a loop of its own with a quantum exit (musl
 * __rem_pio2_large's `while (iq[jz] == 0)` after its recompute loop). The arm loop is a nested K-loop seeded by the
 * arm's flag in each trip. Each entry is checked §6 against its own C program (cqcheck user). Regenerate arm_loop.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec arm_loop.c -o arm_loop.O1.ll */
#include "CQ.h"
int al_arm(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 1, r, j;
  do {
    acc = acc * 3 + i;
    i++;
    if ((x >> (i + 8)) & 1)
      goto found;
  } while ((x >> i) & 1);
  r = acc;
  goto join;
found:
  j = i;
  while ((x >> (j + 16)) & 1)
    j++;
  r = acc + j * 7;
join:
  return cq_measure(r);
}
/* cq-lgkx: a nested K-loop whose read after it the single-exit forms cannot express (the header phi j itself, the
 * exiting trip's value) takes the general exit capture inside each outer trip. */
int al_nested_read(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 0;
  do {
    int j = i;
    while ((x >> (j + 8)) & 1)
      j++;
    acc = acc * 5 + j;
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
/* cq-lgkx: a nested K-loop exiting from a block other than its latch (a break in its body). */
int al_nested_break(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 1;
  do {
    int j = 0;
    do {
      if ((x >> (j + 12)) & 1)
        break;
      acc += j + i;
      j++;
    } while ((x >> (j + 8)) & 1);
    acc = acc * 3 + j;
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
/* cq-lgkx: a nested K-loop with two live exit blocks (an exit arm of its own inside the outer trip). */
int al_nested_multi(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 1;
  do {
    int j = 0, r;
    do {
      if ((x >> (j + 12)) & 1) {
        r = acc * 7 + j;
        goto out;
      }
      j++;
    } while ((x >> (j + 8)) & 1);
    r = acc + 3 * j;
  out:
    acc = r ^ i;
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
