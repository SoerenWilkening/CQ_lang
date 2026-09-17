/* sx6 — the minimal PRE-EXISTING witness: a tainted narrow value minus a positive
 * constant, with no loop and no control flow.  If this prints 65533 on the
 * ORACLE the missing-`signext` literal defect is fully pre-existing and bd 11qv
 * only adds the first GOLDEN that pins it. */
#include "CQ.h"
int main(void) {
    short a = 0;
    a = cq_theta(a, 0.5);
    a -= 3;
    return (int)cq_measure(a);
}
