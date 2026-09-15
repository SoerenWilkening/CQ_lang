/* b01 — the OWNER'S PROGRAM (bd `zwtm`, owner ruling E4).

   The code below is the owner's ACTIVE code body copied BYTE FOR BYTE from
   example/grover/grover_oracle_uncompute.c as measured 2026-09-15: source
   lines 83-95 followed by 129-131 (the intervening 96-128 are the owner's
   commented-out earlier spellings).  Trailing whitespace and the DOUBLE
   space in the return line are preserved deliberately.

   WARNING for whoever lands the E4 slice: the session brief's reproduction
   of this program is NOT byte-identical to the file -- it normalises a
   trailing space on the blank line inside the loop and the double space in
   `cq_measure(b0[1])  + cq_measure(b0[2])`.  DECISIONS.md E4 records the
   orchestrator as having verified they "match exactly"; they match
   SEMANTICALLY.  E4's drift obligation therefore needs a stated
   normalisation, or it cannot be checked. */
#include "CQ.h"
#include <math.h>

int main(void) {
    int a = 5;
    bool b0[3];
    
    for (int i = 0; i < 3; ++i) {
        if (a >= 3){
            b0[i] = cq_theta(b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }
    
    return cq_measure(b0[0]) + cq_measure(b0[1])  + cq_measure(b0[2]) + cq_measure(a);
}
