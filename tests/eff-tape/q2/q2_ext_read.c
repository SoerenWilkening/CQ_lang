/* Run: CQ_BUILD_DIR=<build> python3 tests/eff-tape/q2/run_q2.py (or driver/cqcc -S tests/eff-tape/q2/q2_ext_read.c --cq-check --cq-entry probe --cq-samples 64
 * -o /tmp/q2.ll: exit 3 (NOT COMPARED); --cq-entry probe_classical: exit 0.) */
/* Rulings Q2 (owner 2026-11-11): a bodiless callee given a pointer into an object that holds a QUANTUM cell at the call
 * gets an unspecified byte (CR 1.3); that input is not compared, and with every input so, the check is NOT COMPARED
 * (exit 3), never PASS. ext_peek has no body: an ordinary host call (classical pointer, no quantum predicate). */
long ext_peek(const long *p);
int probe(int x) {
  cq_theta(&x, 0.3);
  long t[2];
  t[0] = (long)(x & 1) * 86400;
  t[1] = 7;
  long r = ext_peek(&t[1]);
  return cq_measure((int)(r & 3) + (int)t[0]);
}
/* The same callee given only classical memory is compared as before. */
int probe_classical(int x) {
  cq_theta(&x, 0.3);
  long t = 7;
  long r = ext_peek(&t);
  return cq_measure((int)(r & 3) + (x & 1));
}
