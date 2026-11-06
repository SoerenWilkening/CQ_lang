/* tests/loops-cutoff probe (cq-tgmnd; CR rules 9, 14): musl wcsrtombs' shape. A K-loop in one classical arm of the
 * entry, and in the other arm a K-loop whose exit arm holds another K-loop, all exiting into one join whose phi takes a
 * different value on each exit edge. The first unit's binding is excluded from the other arm by its classical facts,
 * and the loop of the exit arm gives the outer unit its value over all its own exit edges. Each entry is checked §6
 * against its own C program (cqcheck user). Regenerate join_units.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec join_units.c -o join_units.O1.ll */
#include "CQ.h"
int ju_units(int x0, long s, long n0, double th) {
  int x = x0; cq_theta(&x, th);
  long n = n0, r;
  int i = 0;
  if (!s) {
    long k = 0;
    while ((x >> i) & 1) {
      if ((x >> (i + 16)) & 1) {
        r = -2;
        goto done;
      }
      k += ((x >> (i + 8)) & 1) + 1;
      i++;
    }
    r = k;
    goto done;
  }
  while (n >= 4) {
    if ((x >> i) & 1) {
      r = n0 - n;
      goto done;
    }
    if ((x >> (i + 16)) & 1) {
      r = -3;
      goto done;
    }
    n -= ((x >> (i + 8)) & 1) + 1;
    i++;
  }
  while (n) {
    if ((x >> i) & 1) {
      r = n0 - n + 100;
      goto done;
    }
    if ((x >> (i + 16)) & 1) {
      r = -1;
      goto done;
    }
    n--;
    i++;
  }
  r = n0;
done:
  return cq_measure(r);
}
