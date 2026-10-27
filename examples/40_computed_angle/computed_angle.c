#include <math.h>
int computed_angle(int x0, int n, int i, double scale) {
    int x = x0;
    double angle = scale * M_PI / (double)(n + 1) + (double)i * 0.5;
    cq_theta(&x, angle);
    return cq_measure(x);
}
