/* Grover search over n qubits for one marked element (Nielsen & Chuang 6.1).
 *
 *   grover(n, marked)   1 <= n <= GROVER_MAX_N, 0 <= marked < 2^n; returns the measured register,
 *                       qubit i in bit i, or -1 for arguments out of range.
 *
 * A = Ry(pi/2) on every qubit maps |0...0> to the uniform superposition (it plays the role of the
 * Hadamard layer; every amplitude is +1/sqrt(2^n)). One Grover iteration is G = A R0 A^dag O:
 *   O    the phase oracle, a phase pi on the branch where the register equals `marked`;
 *   R0   a phase pi on every branch where the register is not 0 (2|0><0| - I up to a global sign);
 *   A^dag  the adjoint of the preparation, written as `prepare` inside cq_invert.
 * After floor(pi/4 * sqrt(2^n)) iterations, P(marked) = sin^2((2r+1) asin(2^(-n/2))):
 * 0.945 for n = 3, 0.961 for n = 4, 0.999 for n = 5.
 *
 * The register is a bool array, one qubit per element (see examples/README.md). n is a classical
 * argument: every loop bound is classical, only the register is quantum. */
#include <math.h>
#include <stdbool.h>

#define GROVER_MAX_N 16

/* A: Ry(pi/2) on each of the n qubits. */
static void prepare(bool *x, int n) {
    for (int i = 0; i < n; i++)
        cq_theta(&x[i], M_PI / 2);
}

/* The register read as an unsigned integer, qubit i in bit i. */
static unsigned value(const bool *x, int n) {
    unsigned v = 0;
    for (int i = 0; i < n; i++)
        v |= (unsigned)x[i] << i;
    return v;
}

int grover(int n, unsigned marked) {
    if (n < 1 || n > GROVER_MAX_N || marked >= (1u << n))
        return -1;
    int iterations = (int)floor(M_PI / 4 * sqrt((double)(1u << n)));

    bool x[GROVER_MAX_N] = {0};
    prepare(x, n);
    for (int r = 0; r < iterations; r++) {
        if (value(x, n) == marked)      /* O */
            cq_phi(M_PI);
        cq_invert_begin();              /* A^dag */
        prepare(x, n);
        cq_invert_end();
        if (value(x, n) != 0)           /* R0 */
            cq_phi(M_PI);
        prepare(x, n);                  /* A */
    }

    int result = 0;
    for (int i = 0; i < n; i++)
        result |= cq_measure(x[i]) << i;
    return result;
}

/* Entry points for `cqcheck user`: fixed sizes, so the checker samples only the qubits. */
int grover_3(void) { return grover(3, 5); }
int grover_4(void) { return grover(4, 11); }
