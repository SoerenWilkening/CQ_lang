/* gsl_blas_dgemv: y = A x for a 2x2 matrix, one entry of x with two quantum bits. */
#include <gsl/gsl_blas.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double a[] = {1.0, 2.0, 3.0, 4.0};
    double xv[] = {(double)(q & 3), 1.0};
    double yv[] = {0.0, 0.0};
    gsl_matrix_view A = gsl_matrix_view_array(a, 2, 2);
    gsl_vector_view x = gsl_vector_view_array(xv, 2);
    gsl_vector_view y = gsl_vector_view_array(yv, 2);
    gsl_blas_dgemv(CblasNoTrans, 1.0, &A.matrix, &x.vector, 0.0, &y.vector);
    return cq_measure((int)(yv[0] + yv[1]));
}
