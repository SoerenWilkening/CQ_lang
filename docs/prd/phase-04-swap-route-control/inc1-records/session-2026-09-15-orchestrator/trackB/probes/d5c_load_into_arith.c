/* d5c — a bank load into ARITHMETIC.  `lowerOps` would mint templates on a rail
   nothing owns. */
#include "CQ.h"
int main(void) {
    bool b0[2]; 
    for (int i = 0; i < 2; ++i) b0[i] = cq_theta(b0[i], 0.5);
    return (int) b0[0] + (int) b0[1];
}
