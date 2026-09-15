#include "CQ.h"
/* R13 ATTACK: the user wrote a QUANTUM measurement, `cq_measure(q + u)`, whose
   operand -O1 folds to a whole-value `undef` (add X, undef -> undef). Does the
   user's quantum measurement silently become a classical zero? */
int main(void){ int u = 0; int q = cq_theta(0, 0.3); return cq_measure(q + u); }
