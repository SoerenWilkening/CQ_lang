/* Shor order finding for N = 15, a = 7 (r = 4): the quantum part of the textbook program.
 *   counting register x[0..T-1] (x[0] = LSB), work register y
 *   1. H on every counting qubit            H|0> = Ry(pi/2)|0>
 *   2. y = a^x mod N by repeated squaring   controlled y *= a^(2^j) mod N  (the loop of example 62)
 *   3. inverse QFT on the counting register (the loops of example 60; H = Ry(pi/2)·Z on a superposed qubit)
 *   4. measure m and y; the continued-fraction post-processing is classical and left out.
 * Expected: m uniform on {0, 2, 4, 6}, y in {1, 7, 4, 13} correlated with x (period r = 4). */
#include <stdbool.h>
#include <math.h>
#define N 15u
#define A 7u
#define T 3
unsigned shor15(void) {
    bool x[T] = {0};
    for (int j = 0; j < T; j++)
        cq_theta(&x[j], M_PI / 2);
    unsigned y = 1, ap = A % N;
    for (int j = 0; j < T; j++) {
        if (x[j]) y = (y * ap) % N;
        ap = (ap * ap) % N;
    }
    for (int j = 0; j < T; j++) {                  /* logical qubit j is x[T-1-j] (final swaps folded into the labels) */
        for (int k = 0; k < j; k++)
            if (x[T - 1 - k] && x[T - 1 - j]) cq_phi(-M_PI / (double)(1u << (j - k)));
        if (x[T - 1 - j]) cq_phi(M_PI);
        cq_theta(&x[T - 1 - j], M_PI / 2);
    }
    unsigned m = 0;
    for (int j = 0; j < T; j++)
        m |= (unsigned)cq_measure(x[T - 1 - j]) << j;
    unsigned yv = cq_measure(y);
    return m | (yv << 8);
}
