#include "CQ.h"
/* E2 q1: the DIRECT spelling of clause 4. `bool b;` read uninitialized at the sink.
   The fixture header of lowering_reject_measure_undef_operand.ll names exactly this
   C customer (trackC probe c6_undef_bool.c). Expect: D on the clause-4 string. */
int main(void){ _Bool b; return cq_measure(b); }
