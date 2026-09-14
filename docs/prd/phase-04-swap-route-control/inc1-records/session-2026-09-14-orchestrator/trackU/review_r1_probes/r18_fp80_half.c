/* widths not fixtured from C: long double (x86_fp80) and _Float16 (half) */
#include "CQ.h"
int main(void) {
    long double ld;
    ld = cq_theta(ld, 0.5);
    return (int)cq_measure(ld);
}
