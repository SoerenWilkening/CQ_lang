#include "CQ.h"
/* §14: two siblings off a MEASURED name. Under the ruling both are legal (two fresh
   allocs seeded from the same outcome). Today this is the bd 3d8q defect shape. */
int main(void){ int q=cq_theta(0,0.3); int m=cq_measure(q);
  int b=cq_theta(q,0.5); int c=cq_theta(q,0.9); return m+cq_measure(b)+cq_measure(c); }
