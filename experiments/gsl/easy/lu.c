/* gsl_linalg_LU_decomp with partial pivoting on a 2x2 matrix, one entry with two quantum bits. The pivot row depends on the data. */
#include <gsl/gsl_linalg.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double a[] = {x, 2.0, 1.5, 4.0};
    gsl_matrix_view A = gsl_matrix_view_array(a, 2, 2);
    gsl_permutation *p = gsl_permutation_alloc(2);
    int s;
    gsl_linalg_LU_decomp(&A.matrix, p, &s);
    return cq_measure((int)(4.0 * gsl_linalg_LU_det(&A.matrix, s)));
}
