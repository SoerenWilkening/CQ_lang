/* u4: _Bool twin -- if (b) c = cq_theta(b, th) */
#include "CQ.h"
int main(void){ _Bool b = cq_theta((_Bool)0, 0.25); _Bool c = b;
  if (b) c = cq_theta(b, 0.9);
  return cq_measure(c); }
