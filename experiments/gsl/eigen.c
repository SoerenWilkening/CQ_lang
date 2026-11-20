/* GSL's symmetric eigensolver on quantum data: the off-diagonal entry of a 2x2 symmetric matrix is in
 * superposition over 0..3, so the eigenvalues are computed for four matrices at once. Links the lowered
 * GSL (../lib/gsl/libq_*.a) and libc; nothing of either is lowered again here. ./run_eigen.sh */
#include <gsl/gsl_eigen.h>
#include <gsl/gsl_errno.h>
int main(void) {
    gsl_set_error_handler_off();                      /* GSL's default handler prints and aborts; see run notes */
    unsigned char q = 0;
    cq_theta(&q, M_PI_2);
    double a = (double)(q & 3);                       /* two quantum bits */

    double data[] = {2.0, a, a, 1.0};
    gsl_matrix_view m = gsl_matrix_view_array(data, 2, 2);
    gsl_vector *eval = gsl_vector_alloc(2);
    gsl_eigen_symm_workspace *w = gsl_eigen_symm_alloc(2);
    gsl_eigen_symm(&m.matrix, eval, w);
    return cq_measure((int)gsl_vector_get(eval, 0));
}
