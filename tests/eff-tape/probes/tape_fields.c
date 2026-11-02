#include "CQ.h"
#include <signal.h>
#include <stdio.h>
#include <unistd.h>
/* cq-a63l (CR rule 16 fields, f684858): the field forms of a tape entry. */
int fwrite_stream(int c, int n, FILE *f) {  /* another stream, a run-time count: an effect entry, the FILE * an i64
                                               literal, the buffer a classical loop of byte fields */
  int x = cq_theta_si32(c, 1.0);
  char buf[16] = "abcdefghijklmno";
  if (x > 3)
    fwrite(buf, 1, n, f);
  return cq_measure_si32(x);
}
int write_qlen(int c) {                     /* write(fd, slot cells, quantum length): one i8 field per cell up to
                                               the bound, each controlled under len > j */
  int x = cq_theta_si32(c & 3, 1.0);
  char buf[4] = {'a', 'b', 'c', 'd'};
  buf[0] = (char)x;
  if (x > 1)
    write(1, buf, (unsigned)x);
  return cq_measure_si32(x);
}
int printf_runtime_fmt(int c, int k, const char *fmt, void *p) {  /* a run-time format: _lit, a pointer its
                                               address; the format may hold %n: snprintf(0, 0, ...) in front */
  int x = cq_theta_si32(c, 1.0);
  if (x > 3)
    printf(fmt, k, p);
  return cq_measure_si32(x);
}
int kill_effect(int c, int pid) {            /* kill under a quantum predicate: an effect entry */
  int x = cq_theta_si32(c, 1.0);
  if (x > 3)
    kill(pid, SIGUSR1);
  return cq_measure_si32(x);
}
int str_slot(int c) {                        /* %s whose bytes are handles: tape_str_begin/end */
  int x = cq_theta_si32(c & 0x7f, 1.0);
  char s[3] = {'a', 0, 0};
  s[1] = (char)x;
  printf("%s\n", s);
  return cq_measure_si32(x);
}
