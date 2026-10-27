#include <stdbool.h>
void qft(bool *q, int n, double base) {
    for (int i = 0; i < n; i++) {
        cq_theta(&q[i], base);
        for (int j = i + 1; j < n; j++)
            if (q[j] && q[i])
                cq_phi(base / (double)(1 << (j - i)));
    }
}
