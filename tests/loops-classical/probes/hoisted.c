#include "CQ.h"
/* cq-ot39: -O1 LICM hoists a quantum loop invariant into the guarded preheader (review lcw-h2 k3, k1; lcw-h1 c4). */
int fk3(int x0, double th, int n) {
    int x = x0; cq_theta(&x, th);
    int s = 0;
    for (int i = 0; i < n; i++) { s = (s ^ i) + x * 3; }
    return cq_measure(s);
}
int fk1(int x0, double th, int n) {
    int x = x0; cq_theta(&x, th);
    int s = 0;
    for (int i = 0; i < n; i++) { int t = x * 3; int u = t + i; cq_theta(&u, th); s = s + u * u; }
    return cq_measure(s);
}
int c4(int x0, double th, int n) {
    int x = x0;
    cq_theta(&x, th);
    int acc = 0;
    for (int i = 0; i < n; i++) {
        if (i & 1) acc = acc * 5 + x;
        else acc = acc - (x << 1);
    }
    return cq_measure(acc);
}
