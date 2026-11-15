/* tests/loops-cutoff probe (cq-9kcq S11e; CR rules 14, 16): nested abort/exit arms: a nested K-loop with a noreturn arm
 * inside a K-loop's trip; its stop rail is carried across the inner trips and read by the outer trip. §6-checked against
 * its C program. Regenerate nstop.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec nstop.c -o nstop.O1.ll */
#include <stdlib.h>
#include "CQ.h"
int ns_inner(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 1;
  do {
    int j = 0;
    while ((x >> (j + 8)) & 1) {
      if (((x >> (j + 12)) & 3) == 3)
        abort();
      j++;
    }
    acc = acc * 3 + j + i;
    i++;
  } while ((x >> i) & 1);
  return cq_measure(acc);
}
int ns_nest(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int i = 0, acc = 0;
  while ((x >> i) & 1) {
    int j = i;
    do {
      if (((x >> (j + 4)) & 7) == 5)
        exit(3);
      j++;
    } while ((x >> (j + 8)) & 1);
    acc += j;
    i++;
  }
  return cq_measure(acc);
}
