#include <CQ.h>
#include <math.h>
int main(void) {


  double x = cq_theta(0.0, 0.5); double ip; double fp = modf(x, &ip); return cq_measure((int)fp) + cq_measure((int)ip);
}
