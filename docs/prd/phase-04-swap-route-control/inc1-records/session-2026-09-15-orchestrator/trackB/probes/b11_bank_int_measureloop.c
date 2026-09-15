/* b11 — b10 with the measures in a LOOP, so every access is the same
   `[3 x i32]` gep shape. Discriminates "int cells" from "constant-index
   byte-offset gep". */
#include "CQ.h"
int main(void) {
    int b0[3]; int s = 0;
    for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
    for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
    return s;
}
