/* GMP's mpn_fib2_ui(fp, f1p, n) with n in superposition over 0..7: for n below 94 GMP reads F(n) and F(n-1) from a
 * table, so this is a table lookup at a quantum index. */
#include <gmp.h>
mp_size_t __gmpn_fib2_ui(mp_ptr, mp_ptr, unsigned long);   /* internal to GMP: not in gmp.h */
#define mpn_fib2_ui __gmpn_fib2_ui
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    mp_limb_t f[4] = {0}, f1[4] = {0};
    mpn_fib2_ui(f, f1, (unsigned long)(q & 7));
    return cq_measure((int)f[0]);
}
