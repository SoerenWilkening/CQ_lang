/* gsl_blas_dgemm: C = A B for 2x2 matrices, one entry of A with two quantum bits. */
#include <gsl/gsl_blas.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double a[] = {x, 2.0, 3.0, 4.0}, b[] = {1.0, 0.5, 2.0, 1.0}, c[4] = {0};
    gsl_matrix_view A = gsl_matrix_view_array(a, 2, 2), B = gsl_matrix_view_array(b, 2, 2), C = gsl_matrix_view_array(c, 2, 2);
    gsl_blas_dgemm(CblasNoTrans, CblasNoTrans, 1.0, &A.matrix, &B.matrix, 0.0, &C.matrix);
    return cq_measure((int)(c[0] + c[1] + c[2] + c[3]));
}
