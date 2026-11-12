/* A program built against musl's <stdio.h>: the standard stream is `FILE *const stdout`, which the host (Darwin)
   names __stdoutp (ruling Q6: the bundle defines no stdout). The written text is compared as stdout. */
#include "CQ.h"
typedef struct _IO_FILE FILE;
extern FILE *const stdout;
int fprintf(FILE *, const char *, ...);
int f(int x) {
  cq_theta(&x, 0.3);
  fprintf(stdout, "%d|", x);
  cq_measure(x);
  return 0;
}
