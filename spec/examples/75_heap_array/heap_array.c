#include <stdlib.h>
int heap_array(unsigned x0, double th, int n, int k) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *a = malloc(n * sizeof *a);             /* heap array, classical size */
    for (int i = 0; i < n; i++)
        a[i] = x + i;                           /* cells hold quantum values */
    int r = a[k] + a[n - 1];                    /* read back at classical indices */
    free(a);
    return cq_measure(r);
}
