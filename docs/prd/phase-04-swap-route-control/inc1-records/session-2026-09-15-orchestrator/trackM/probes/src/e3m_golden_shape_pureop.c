#include "CQ.h"
/* E3 GOLDEN SHAPE: `int keep = cq_measure(y); int x = (y != 0);` — the exact shape
   IMPL_D.md §14.6 names as the only 2 shipped goldens whose STREAM moves. */
int main(void){ int y=cq_theta(0,0.3); int keep=cq_measure(y); int x=(y!=0); return keep+x; }
