#include "CQ.h"
int main(void){ int q = cq_theta(0, 0.7); bool k[3];
  int i = 0;
  if ((q >> i) & 1) k[i] = cq_theta(k[i], 0.5); i = i + 1;
  if ((q >> i) & 1) k[i] = cq_theta(k[i], 0.5); i = i + 1;
  if ((q >> i) & 1) k[i] = cq_theta(k[i], 0.5); i = i + 1;
  return cq_measure(k[0]) + cq_measure(k[1]) + cq_measure(k[2]) + cq_measure(q); }
