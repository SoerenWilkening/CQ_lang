#include "CQ.h"
/* R13 (bd 1yeu — every corpus in the tree is one function per module): the undef
   measure is in fn A; fn B carries the real quantum content. On the ORACLE the
   FIRST DS_Error kills the module, so B never lowers. */
__attribute__((noinline)) int a_undef(void){ int u; return cq_measure(u); }
__attribute__((noinline)) int b_quantum(void){ int q = cq_theta(0, 0.3); return cq_measure(q); }
int main(void){ return a_undef() + b_quantum(); }
