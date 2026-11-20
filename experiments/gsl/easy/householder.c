/* gsl_linalg_solve_tridiag is avoided; gsl_linalg_HH_svx: solve a 2x2 system by Householder, one matrix entry with two quantum bits. */
#include <gsl/gsl_linalg.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double a[] = {4.0, x, 1.0, 3.0}, b[] = {1.0, 2.0};
    gsl_matrix_view A = gsl_matrix_view_array(a, 2, 2);
    gsl_vector_view v = gsl_vector_view_array(b, 2);
    gsl_linalg_HH_svx(&A.matrix, &v.vector);
    return cq_measure((int)(16.0 * b[0]));
}
