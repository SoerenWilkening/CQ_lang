#include "CQ.h"
int slice(void) {
    int y = cq_theta(5, 0.5);
    int s = 0;
    { int u = cq_theta(6, 0.4);
      s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
      u = cq_theta(u, 0.9);
      s += cq_measure(u); }
    { int u = cq_theta(6, 0.4);
      s += cq_measure((u >> 1) & 1) + cq_measure(y & 1);
      u = cq_theta(u, 0.9);
      s += cq_measure(u); }
    y = cq_theta(y, 0.7);
    return s + cq_measure(y);
}
int main(void) { return slice(); }
