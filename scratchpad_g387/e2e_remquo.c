#include <CQ.h>
#include <math.h>
int main(void) {
  double x = cq_theta(0.0, 0.5); double y = cq_theta(0.0, 0.3); int q; double r = remquo(x, y, &q); return cq_measure((int)r) + cq_measure(q);


}
