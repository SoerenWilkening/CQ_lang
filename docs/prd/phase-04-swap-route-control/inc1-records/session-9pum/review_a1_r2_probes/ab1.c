#include <stdlib.h>
int slice(void) {
    int q = cq_theta(5, 0.5);
    int q2 = cq_theta(q, 0.9);      /* staler on q's wire, BEFORE the branch */
    if (q > 5) abort();
    return cq_measure(q2);
}
int main(void){ (void) slice(); return 0; }
