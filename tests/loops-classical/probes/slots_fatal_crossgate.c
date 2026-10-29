/* tests/loops-classical fatal probe (cq-sujx): a carried sum reads a slot cell, then the cell is rotated in the same trip.
 * The reverse loop would undo the sum after the rotation (rule 5's invariant across trips): cq::unimplemented. */
#include <stdbool.h>
#include "CQ.h"
int f_crossgate(const double *th, int n) {
  bool q[n];
  for (int i = 0; i < n; i++) q[i] = 0;
  for (int i = 0; i < n; i++) cq_theta(&q[i], th[i]);
  int acc = 0;
  for (int i = 0; i < n; i++) { acc += q[i]; cq_theta(&q[i], th[i]); }
  return cq_measure(acc);
}
