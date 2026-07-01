#include <CQ.h>
#include <math.h>
int main(void) {

  double x = cq_theta(0.0, 0.5); int e; double m = frexp(x, &e); return cq_measure((int)m) + cq_measure(e);

}
