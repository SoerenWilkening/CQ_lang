/* gsl_blas_ddot: dot product of two 4-vectors, one entry with two quantum bits. */
#include <gsl/gsl_blas.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double x = (double)(q & 3);                       /* two quantum bits */
    double a[] = {1.0, x, 3.0, 4.0}, b[] = {2.0, 5.0, 1.0, 3.0}, r = 0;
    gsl_vector_view u = gsl_vector_view_array(a, 4), v = gsl_vector_view_array(b, 4);
    gsl_blas_ddot(&u.vector, &v.vector, &r);
    return cq_measure((int)r);
}
