/* gsl_linalg_cholesky_decomp1: Cholesky factor of a 2x2 symmetric positive definite matrix, the off-diagonal entry q/4 with two quantum bits. */
#include <gsl/gsl_linalg.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double a[] = {4.0, x / 4.0, x / 4.0, 3.0};
    gsl_matrix_view A = gsl_matrix_view_array(a, 2, 2);
    gsl_linalg_cholesky_decomp1(&A.matrix);
    return cq_measure((int)(16.0 * a[3]));
}
