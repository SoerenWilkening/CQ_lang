/* Dicke state |D^4_2>, Bärtschi & Eidenbenz (2019): start |0011>, then SCS_{4,2}, SCS_{3,2}, SCS_{2,1}.
 * Plain C gates: a CNOT is `t ^= c`, a CRy is `if (c) cq_theta(&t, a)`, a CCRy is `s = 2*a + b; if (s == 3) cq_theta(&t, a)`.
 * The result is the four measured bits, q1 in bit 0. */
#include <math.h>
int dicke4(void) {
    bool q1 = 0, q2 = 0, q3 = 1, q4 = 1;
    int s;
    /* SCS_{4,2} */
    q4 ^= q3;
    if (q4) cq_theta(&q3, 2.0 * acos(sqrt(1.0 / 4)));
    q4 ^= q3;
    q4 ^= q2;
    s = 2 * q4 + q3;
    if (s == 3) cq_theta(&q2, 2.0 * acos(sqrt(2.0 / 4)));
    q4 ^= q2;
    /* SCS_{3,2} */
    q3 ^= q2;
    if (q3) cq_theta(&q2, 2.0 * acos(sqrt(1.0 / 3)));
    q3 ^= q2;
    q3 ^= q1;
    s = 2 * q3 + q2;
    if (s == 3) cq_theta(&q1, 2.0 * acos(sqrt(2.0 / 3)));
    q3 ^= q1;
    /* SCS_{2,1} */
    q2 ^= q1;
    if (q2) cq_theta(&q1, 2.0 * acos(sqrt(1.0 / 2)));
    q2 ^= q1;
    return cq_measure(q1) | cq_measure(q2) << 1 | cq_measure(q3) << 2 | cq_measure(q4) << 3;
}
