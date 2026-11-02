#include "CQ.h"
#include <stdio.h>
#include <unistd.h>
/* cq-a63l (CR rule 16 fields over rule 21): bytes and address of a quantum pointer. */
int fat_str(int c) {
  int x = cq_theta_si32(c & 1, 0.8);
  char a[3] = "ab", b[4] = "xyz";
  const char *p = x ? a : b;
  printf("%s\n", p);
  return cq_measure_si32(x);
}
int fat_write(int c) {
  int x = cq_theta_si32(c & 1, 0.8);
  char a[2] = {'a', 'b'}, b[2] = {'x', 'y'};
  const char *p = x ? a : b;
  write(1, p, 2);
  return cq_measure_si32(x);
}
