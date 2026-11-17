#include <stdio.h>
int printf_double(double x0, double th) {
    double x = x0;
    cq_theta(&x, th);
    printf("%f\n", x);                     /* a quantum double on the tape */
    return cq_measure(x) > 0.0;
}
int printf_compound_cond(int x0, int y0, double tx, double ty, int k, int m) {
    int x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    if (x > k && y > m)                    /* compound quantum condition */
        printf("both %d %d\n", x, y);
    return cq_measure(x) + cq_measure(y);
}
int printf_nested_cond(int x0, int y0, double tx, double ty, int k, int m) {
    int x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    if (x > k) {
        if (y > m)
            printf("inner %d\n", y);       /* nested quantum conditions */
        printf("outer %d\n", x);
    }
    return cq_measure(x) + cq_measure(y);
}
