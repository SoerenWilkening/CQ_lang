/* cq-wskg (gate 2a taint-h2 p20_sj): a longjmp through a defined noreturn wrapper called under a quantum
   predicate in the entry itself (rule 24, cq-lyzw). Formerly an error probe. */
#include "CQ.h"
#include <setjmp.h>
static jmp_buf b;
int X;
__attribute__((noinline)) static void jump(void) { longjmp(b, 1); }
void p20(int i) {
  int q = cq_theta_si32(i, 1.0);
  X = 0;
  if (setjmp(b) != 0) { X = 5; return; }
  if (q > 0) jump();
}
