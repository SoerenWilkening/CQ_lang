/* CR rule 17 (2026-11-02, cq-asfn): a cq_invert marker the program writes inside a quantum arm. The marker is a
 * host call executed on every path; the arm's gates carry the arm flag.
 *  p_armpair:  begin and end both in one quantum arm (the region holds the arm's controlled gates).
 *  p_armbegin: begin in a quantum arm, its end after the join: the tail is lowered under f inside the bracket
 *              and under not f outside it (A1|f, B|not f, begin, A2|f, T|f, end, T|not f up to commuting).
 *  p_armend:   end in a quantum arm, its begin before the branch: begin, prefix, B|not f, T|not f, A1|f, end,
 *              A2|f, T|f (T runs to the return: on the other path the region stays open; y is returned as its
 *              handle, unmeasured, since a measurement in T would be lowered once per copy).
 *  p_armnest:  begin in an arm nested in a quantum arm, end after both joins. */
#include "CQ.h"
int p_armpair(int x0, double th, int k, double a, double b, double c) {
  int x = x0; cq_theta(&x, th);
  if (x == k) {
    cq_phi(a);
    cq_invert_begin();
    cq_theta(&x, b);
    cq_phi(b);
    cq_invert_end();
  } else {
    cq_phi(c);
  }
  return cq_measure(x);
}
int p_armbegin(int x0, double th, int y0, double ty, int k, double a, double b, double c, double d) {
  int x = x0; cq_theta(&x, th);
  int y = y0; cq_theta(&y, ty);
  if (x == k) {
    cq_phi(a);
    cq_invert_begin();
    cq_theta(&y, b);
  } else {
    cq_theta(&y, c);
  }
  cq_theta(&y, d);
  if (y > 2) cq_phi(d);
  cq_invert_end();
  cq_theta(&y, a);
  return cq_measure(x) + cq_measure(y);
}
int p_armend(int x0, double th, int y0, double ty, int k, double a, double b, double c, double d) {
  int x = x0; cq_theta(&x, th);
  int y = y0; cq_theta(&y, ty);
  cq_invert_begin();
  cq_theta(&y, a);
  if (x == k) {
    cq_theta(&y, b);
    cq_invert_end();
    cq_phi(b);
  } else {
    cq_theta(&y, c);
  }
  cq_theta(&y, d);
  return y;
}
int p_armnest(int x0, double th, int y0, double ty, int k, int m, double a, double b, double c) {
  int x = x0; cq_theta(&x, th);
  int y = y0; cq_theta(&y, ty);
  if (x > k) {
    cq_theta(&y, a);
    if (y < m) {
      cq_invert_begin();
      cq_theta(&x, b);
    }
    cq_phi(c);
  }
  cq_theta(&y, c);
  cq_invert_end();
  return cq_measure(x) + cq_measure(y);
}
