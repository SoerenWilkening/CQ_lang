#include <stdbool.h>
int register_array(const double *theta, int n) {
    bool q[n];
    for (int i = 0; i < n; i++)
        q[i] = 0;
    for (int i = 0; i < n; i++)
        cq_theta(&q[i], theta[i]);
    int e = 0;
    for (int i = 0; i < n; i++)
        e += cq_measure(q[i]);
    return e;
}
