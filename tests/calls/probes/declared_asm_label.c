// cq-dv19x: a listed function with a Darwin asm label ("\\01_ext_lab" in the IR) is __cq_q_ext_lab_*, not __cq_q_\\01_ext_lab_*.
#include "CQ.h"
int ext_lab(int x) __asm("_ext_lab");
int e(int a) { int x = a; cq_theta(&x, 1.0); return cq_measure(ext_lab(x)); }
