/* GMP's mpn_fib2_ui(fp, f1p, n) with n in superposition over 96..99: above the table, so the doubling
 * recurrence runs (squarings and additions of multi-limb numbers), with the low bits of n quantum. */
#include <gmp.h>
mp_size_t __gmpn_fib2_ui(mp_ptr, mp_ptr, unsigned long);   /* internal to GMP: not in gmp.h */
#define mpn_fib2_ui __gmpn_fib2_ui
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    mp_limb_t f[8] = {0}, f1[8] = {0};
    mpn_fib2_ui(f, f1, 96ul + (q & 3));
    return cq_measure((int)(f[0] & 0xffff));
}
