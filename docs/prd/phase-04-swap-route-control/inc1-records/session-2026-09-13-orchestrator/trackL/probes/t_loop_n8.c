/* t_loop_n8.c — Track L probe, session 2026-09-13. READ-ONLY scoping.
   VERDICT on the ORACLE (build/ir-pass/cq-opt sha256 fbbe0820…, e96f89c):
   As t_loop_n2, N=8.
   ⚠ RETIREMENT TRIGGER (L8): as s_loop_n2. */
#include "CQ.h"
int main(void) {
    int a = 5;
    bool b = cq_theta((bool)0, 0.0);
    for (int i = 0; i < 8; ++i) {
        if (a >= 3) b = cq_theta(b, 0.5);
        if (b) a -= 3;
    }
    return cq_measure(a) + cq_measure(b);
}
