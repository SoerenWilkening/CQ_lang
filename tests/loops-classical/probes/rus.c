/* cq-qb3n (CR rules 2, 5): repeat-until-success. A classical do-while measures, every trip, a classical join of the
 * carried value and an arm's update of it. The join is measured on every path, its arms (the arm's result, the
 * previous trip's outcome seed, trip 0's initial value) on some only: the measurement reads a kept copy and the
 * trip's reverse undoes the arms. Each entry is checked §6 against its own C program. Regenerate rus.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec rus.c -o rus.O1.ll */
#include "CQ.h"
volatile int rus_g;
int rus_xor(int x0, double th, int n, int c) {
  int x = x0; cq_theta(&x, th);
  int v = x + 1;
  int s = 0, i = 0;
  do {
    if ((c >> i) & 1) { rus_g = 2; v = v ^ (i + 3); }
    s += cq_measure(v);
    i++;
  } while (i < n);
  return s;
}
int rus_mul(int x0, double th, int n, int c) {
  int x = x0; cq_theta(&x, th);
  int v = x * 3;
  int s = 0, i = 0;
  do {
    if ((c >> i) & 1) v = v * 5 + i;
    else v = v - c;
    s = s * 2 + cq_measure(v);
    i++;
  } while (i < n);
  return s;
}
