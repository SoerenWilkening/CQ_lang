/* GSL's Jacobi eigensolver on quantum data: the off-diagonal entry of a 2x2 symmetric matrix is in superposition
 * over 0..3. Jacobi sweeps visit every (p, q) pair in a fixed order, so no array index depends on the data
 * (gsl_eigen_symm's deflation makes its indices data-dependent, which needs quantum-addressed memory). */
#include <gsl/gsl_eigen.h>
int main(void) {
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double a = (double)(q & 3);                       /* two quantum bits */

    double data[] = {2.0, a, a, 1.0};
    gsl_matrix_view m = gsl_matrix_view_array(data, 2, 2);
    gsl_vector *eval = gsl_vector_alloc(2);
    gsl_matrix *evec = gsl_matrix_alloc(2, 2);
    unsigned int nrot = 0;
    gsl_eigen_jacobi(&m.matrix, eval, evec, 4, &nrot);
    return cq_measure((int)gsl_vector_get(eval, 0));
}
