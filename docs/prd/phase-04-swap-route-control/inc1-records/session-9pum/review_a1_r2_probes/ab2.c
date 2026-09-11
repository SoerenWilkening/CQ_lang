#include <stdlib.h>
int slice(void) {
    int q = cq_theta(5, 0.5);
    int m = cq_measure(q);
    if (q > 5) abort();
    return m;
}
int main(void){ (void) slice(); return 0; }
