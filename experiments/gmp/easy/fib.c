/* GMP's Fibonacci: mpz_fib_ui(f, n) with n in superposition over 0..7 (three qubits), so F(0)..F(7) at once. */
#include <gmp.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    unsigned long n = q & 7;
    mpz_t f;
    mpz_init(f);
    mpz_fib_ui(f, n);
    return cq_measure((int)mpz_get_ui(f));
}
