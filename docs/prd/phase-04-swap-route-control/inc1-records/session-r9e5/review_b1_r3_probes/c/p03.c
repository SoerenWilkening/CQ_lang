/* p03 — AREA 7 ("the spine"): a chain that BORROWS the rail as its parent,
   with a 4.4 RAIL SELECT between the chain's forward gate and its uncompute
   point. `Uncomputation::preservesBorrowedParent` admits an uncontrolled
   `cqrt_rz_` on a borrowed parent BY NAME (clause 1) but lists `cqrt_cnot` under
   "everything else is a mutation" — so the select's copy-flag cnot may cost the
   borrower its discharge where the kickback's rz does not. A LEAK either way
   (Rule 6 safe); measured for the record. */
#include "CQ.h"
int main(void) {
    _Bool b = cq_theta(0, 0.25);
    int d = (int) b + 3;          /* a chain borrowing the rail */
    int a = b ? 2 : 5;            /* the 4.4 rail select between */
    return cq_measure(a) + cq_measure(d);
}
