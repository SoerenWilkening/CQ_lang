#include <CQ.h>
#include <math.h>
__attribute__((noinline))
void slice(double xin) {
    double x = cq_theta(xin, 0.25);   /* source; feeds BOTH producers (fan-out) */
    int e;
    double m = frexp(x, &e);          /* mantissa + exponent producers          */
    (void) cq_phi((int)m, 0.5);       /* keep-alive mantissa chain; dropped     */
    (void) cq_phi(e, 0.6);            /* keep-alive exponent chain; dropped     */
}
int main(void) { slice(0.7); return 0; }
