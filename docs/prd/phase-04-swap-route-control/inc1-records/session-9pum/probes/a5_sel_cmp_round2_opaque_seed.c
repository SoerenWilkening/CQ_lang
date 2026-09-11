#include "CQ.h"
volatile int gint = 0;
int main(void){ int x = gint; int b = cq_theta(x, 0.5); int b3 = cq_theta(x, 0.9);
  int a = (b == 1) ? 2 : 5; return cq_measure(a) + cq_measure(b3); }
