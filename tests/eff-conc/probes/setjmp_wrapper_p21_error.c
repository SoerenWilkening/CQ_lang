/* cq-wskg (gate 2a taint-h2 p21_sj): a longjmp through a defined noreturn wrapper called under a quantum
   predicate in the entry itself; setjmp's result is quantum (taint), and the shape is a loud stop. */
#include "CQ.h"
#include <setjmp.h>
static jmp_buf b;
__attribute__((noinline)) static void jump(void) { longjmp(b, 1); }
void p21(int i) {
  int q = cq_theta_si32(i, 1.0);
  if (setjmp(b) != 0) { cq_phi(0.7); return; }
  if (q > 0) jump();
}
