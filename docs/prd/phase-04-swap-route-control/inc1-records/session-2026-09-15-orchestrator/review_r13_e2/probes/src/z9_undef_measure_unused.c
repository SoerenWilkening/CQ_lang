#include "CQ.h"
/* R13: the user's measurement result is UNUSED. Does a user-written measurement vanish
   with no trace line and no diagnostic? (Rule 5 direction / 7.6 output tape.) */
int main(void){ int u; cq_measure(u); int q = cq_theta(0,0.3); return cq_measure(q); }
