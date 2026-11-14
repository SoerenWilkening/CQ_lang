/* tests/loops-cutoff probe, cq-kbygn exit-test part (owner ruling Q10, 2026-11-11; CR rule 14 "A classical conjunct `C`
 * of the exit test (`while (c && q)`) is a classical branch AT EACH TEST (rule 8): where `C` is false the chain ends
 * there, `a_j` is a `|0>` seed through a classical `phi` of handles and no later trip is emitted; where it is true
 * `a_j = a_{j-1} & Q_j`. `do ... while (c && q)` runs trip 0 whatever `c` is."). Each entry's classical conjunct reads
 * the classical argument m, so the inputs make C false at test 0, false at a later test, and true at every test.
 * Each entry is checked §6 against its own C program (cqcheck user) at K = 4; run_probes.py --br-in counts the `br`.
 * Regenerate exit_conjunct.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec exit_conjunct.c -o exit_conjunct.O1.ll */
#include "CQ.h"

/* (a) `while (c && q)` with c loop-invariant: a branch around the loop (the same as at each test). */
unsigned ec_while(unsigned x0, double th, unsigned k, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0, cell = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  while ((m & 1) && x > k) { x >>= 1; n += 3; *f += n; }
  return cq_measure(x) * 256 + cq_measure(n) * 16 + cq_measure(*f);
}

/* (b) `do ... while (c && q)`: trip 0 runs whatever c is; c re-read at each test (bit i of m). */
unsigned ec_do(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned i = 0, acc = 1, cell = 0;
  unsigned *volatile p = &cell;
  unsigned *f = p;
  do { acc = acc * 3 + x; x >>= 1; *f ^= acc; i++; } while (((m >> i) & 1) && (x & 1));
  return cq_measure(acc) * 256 + cq_measure(*f);
}

/* (c) a classical conjunct that changes inside the loop, the test at the top: bit i of m, i an affine induction (a
 *     classical value in each trip, CR rule 14; no trip bound: rule 14's K-loop). A carried value that is no affine
 *     induction is a rail in a K-loop (taint), so its test is no classical conjunct. */
unsigned ec_vary(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0, i;
  for (i = 0; ((m >> i) & 1) && x > 2; i++) { x = x - 3; s = s * 5 + i; }
  return cq_measure(x) * 64 + cq_measure(s);
}
