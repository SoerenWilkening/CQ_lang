/* The host main of the link test: an ordinary object, linked as is (not lowered). */
#include <stdio.h>
double f_y(double); double f_z(double); int f_k(double); double f_w(int); float f_f(double);
double f_v(double); int f_c(double); double f_m(double); double f_r(double);
int main(void) {
    printf("%.17g %.17g %d %.17g %.9g %g %d %.17g %.17g\n", f_y(2.0), f_z(2.0), f_k(2.0), f_w(1234), (double)f_f(2.0),
           f_v(2.0), f_c(5.0), f_m(2.0), f_r(1.7976931348623157e8));
    return 0;
}
