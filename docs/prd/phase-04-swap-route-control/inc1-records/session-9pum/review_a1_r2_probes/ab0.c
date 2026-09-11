#include <stdlib.h>
int slice(void) {
    int q = cq_theta(5, 0.5);
    if (q > 5) abort();
    return cq_measure(q);
}
int main(void){ (void) slice(); return 0; }
