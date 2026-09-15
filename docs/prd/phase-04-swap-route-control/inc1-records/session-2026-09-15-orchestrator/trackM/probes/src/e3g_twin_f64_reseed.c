#include "CQ.h"
/* E3 WIDTH question at f64 (a non-integer register width). */
int main(void){ double q=cq_theta(0.0,0.3); double m=cq_measure(q); double a=cq_theta(m,0.5); return (int)(m+cq_measure(a)); }
