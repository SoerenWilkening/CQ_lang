/* p28 — DYNAMIC (classical run-time) trip count with a carried bool. */
#include "CQ.h"
int trips(void);
int main(void) {
    bool b = cq_theta((bool)0, 0.5);
    int K = trips();
    for (int i = 0; i < K; i++) { if (b) cq_phi(0.7); b = cq_theta(b, 0.2); }
    return cq_measure(b);
}
