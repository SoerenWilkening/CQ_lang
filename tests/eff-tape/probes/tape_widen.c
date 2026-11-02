#include "CQ.h"
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
/* cq-py5f (CR rule 16, §1.3): tape entries over the class rule 16 describes. */
int pos_printf(int c, int k) {        /* a positional format: the fields in the order printf reads them */
  int x = cq_theta_si32(c, 1.0);
  printf("%2$d %1$d %2$d\n", x, k);
  return cq_measure_si32(x);
}
int runtime_fputs(int c, int k) {     /* after a tape point: fputs of a run-time string is printf("%s", s) */
  int x = cq_theta_si32(c, 1.0);
  printf("x %d\n", x);
  char buf[4] = {'h', 'i', (char)('0' + (k & 7)), 0};
  fputs(buf, stdout);
  return cq_measure_si32(x);
}
int fwrite_classical(int c, int k) {  /* after a tape point: fwrite of classical bytes, read at the call */
  int x = cq_theta_si32(c, 1.0);
  printf("x %d\n", x);
  char buf[3] = {'a', (char)('0' + (k & 7)), '\n'};
  fwrite(buf, 1, 3, stdout);
  return cq_measure_si32(x);
}
int effect_after_tape(int c) {        /* after a tape point: any other host effect is an effect entry, predicate 1 */
  int x = cq_theta_si32(c, 1.0);
  printf("x %d\n", x);
  remove("/tmp/cq_py5f_none");
  return cq_measure_si32(x);
}
int exit_quantum(int c, int k) {      /* exit's status, quantum or not, is dropped: abort_i1(pred) */
  int x = cq_theta_si32(c, 1.0);
  if (x > k) exit(x);
  return cq_measure_si32(x);
}
int abort_flag_rotated(int c, int k) { /* the arm's own condition register rotated after it */
  bool b = cq_theta_i1(c & 1, 1.0);
  if (b && k > 0) abort();
  b = cq_theta_i1(b, 0.5);
  return cq_measure_i1(b);
}
