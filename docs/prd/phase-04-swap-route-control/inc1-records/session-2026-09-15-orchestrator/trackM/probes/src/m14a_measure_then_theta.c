#include "CQ.h"
/* §14 ITEM 1 (owner ruling 2026-09-14): re-using a MEASURED name is legal and should
   lower to a fresh cqrt_alloc seeded from the outcome. What does it do today? */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q); int a=cq_theta(q,0.5); return m+cq_measure(a); }
