#include <stdbool.h>
#include <math.h>
/* Teleportation with feed-forward: a Bell pair (b, c) is built with Ry(pi/2) and a CNOT (b ^ c written into c),
 * the state to send is a on Ry(theta); Bell measurement on (a, b) via CNOT and Ry(-pi/2); the classical outcomes
 * select the corrections on c (X = `c ^= m1`, Z = phase under m2 & c). The recipient un-rotates c by -theta and
 * measures: outcome 0 with probability 1. */
int teleport(double theta) {
    bool a = 0, b = 0, c = 0;
    cq_theta(&a, theta);
    cq_theta(&b, M_PI / 2);
    c = b ^ c;                               /* CNOT b -> c */
    b = a ^ b;                               /* CNOT a -> b */
    cq_theta(&a, -M_PI / 2);                 /* H on a */
    bool m1 = cq_measure(b);
    bool m2 = cq_measure(a);
    if (m1) c = !c;                          /* X correction */
    if (m2 && c) cq_phi(M_PI);               /* Z correction */
    cq_theta(&c, -theta);
    return cq_measure(c);
}
