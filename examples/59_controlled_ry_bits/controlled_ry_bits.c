#include <stdbool.h>
int controlled_ry_chain(const double *theta, int n, double c) {
    bool q[n];
    for (int i = 0; i < n; i++)
        q[i] = 0;
    for (int i = 0; i < n; i++)
        cq_theta(&q[i], theta[i]);
    for (int i = 0; i + 1 < n; i++)
        if (q[i])
            cq_theta(&q[i + 1], c);
    return cq_measure(q[0]) + cq_measure(q[n - 1]);
}
int controlled_ry_two(double t0, double t1, double c) {
    bool q0 = 0, q1 = 0, q2 = 0;
    cq_theta(&q0, t0);
    cq_theta(&q1, t1);
    if (q0 && q1)
        cq_theta(&q2, c);
    return cq_measure(q0) + cq_measure(q1) + cq_measure(q2);
}
