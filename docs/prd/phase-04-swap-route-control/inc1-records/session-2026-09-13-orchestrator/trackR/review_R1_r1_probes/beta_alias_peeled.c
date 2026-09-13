/* The disclosed beta shape (CLAUDE.md CORRECTNESS RISK §4) in its PEELED
   spelling: the prep's straight-through incoming is the LIVE condition register
   `(b0 == 1)`, which -O1 folds to the literal `false` on the pred edge, plus the
   `a = 2` that makes the merge 2-phi and manufactures the clone. */
#include "CQ.h"
int main(void) {
    int  b0 = cq_theta(0, 0.5);
    bool b1 = (b0 == 1);
    int  a  = 5;
    if (b0 == 1) { b1 = cq_theta(b1, 0.5); a = 2; }
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
