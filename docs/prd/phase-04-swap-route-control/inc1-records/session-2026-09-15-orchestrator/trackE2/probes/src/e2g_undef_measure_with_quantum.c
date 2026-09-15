#include "CQ.h"
/* E2 q2: the classical undef measure BESIDE real quantum content — does the
   clause-4 decline preempt an otherwise-accepting module? (Diagnostic ORDER:
   LLVMContext::diagnose EXITS on the first DS_Error.) */
int main(void){ int u; int q = cq_theta(0,0.3); return cq_measure(u) + cq_measure(q); }
