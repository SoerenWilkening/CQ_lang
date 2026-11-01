/* tests/loops-cutoff probes, CR rule 14 (f981c89, cq-rmaf): an affine induction {start,+,step} of a quantum-exit
 * loop is not carried. In trip j it is start + j*step: classical for a classical start, one template from the
 * start rail and the classical offset for a quantum start; a read after the loop gets an exit rail advancing by
 * select on the trip predicate. Each entry is checked against its C program (cqcheck user).
 * Regenerate induction.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec induction.c -o induction.O1.ll */
#include "CQ.h"
/* quantum start, read in the loop and after it (body form, do-while) */
int ind_qstart_exit(int x0, double tx, int n0, double tn) {
  int x = x0, n = n0;
  cq_theta(&x, tx);
  cq_theta(&n, tn);
  do {
    x = x * 3 + n;
    n -= 2;
  } while (x < 100);
  return cq_measure(x) + cq_measure(n);
}
/* quantum start decremented, read by the header test only (region form, 149's shape) */
unsigned ind_qstart_test(unsigned n0, double tn, unsigned k, unsigned c) {
  unsigned n = n0, acc = 0;
  cq_theta(&n, tn);
  while (n > k) {
    acc += n ^ c;
    n--;
  }
  return cq_measure(acc);
}
/* classical start, read in the loop only */
int ind_cstart(int x0, double tx, int i0) {
  int x = x0;
  cq_theta(&x, tx);
  int i = i0;
  do {
    x = x + i;
    i += 3;
  } while (x < 50);
  return cq_measure(x);
}
