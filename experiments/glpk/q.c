/* GLPK's simplex on quantum data: the right-hand side b of one constraint is in superposition,
 * so the linear program is solved for every b in 0..255 at once.
 *   maximize x + y   subject to   x + 2y <= b,   3x + y <= 9,   x, y >= 0 */
#include "glpk.h"
int main(void) {
    unsigned char b = 0;
    cq_theta(&b, M_PI_2);

    glp_prob *lp = glp_create_prob();
    glp_set_obj_dir(lp, GLP_MAX);
    glp_add_rows(lp, 2);
    glp_set_row_bnds(lp, 1, GLP_UP, 0.0, (double)b);
    glp_set_row_bnds(lp, 2, GLP_UP, 0.0, 9.0);
    glp_add_cols(lp, 2);
    glp_set_col_bnds(lp, 1, GLP_LO, 0.0, 0.0);
    glp_set_col_bnds(lp, 2, GLP_LO, 0.0, 0.0);
    glp_set_obj_coef(lp, 1, 1.0);
    glp_set_obj_coef(lp, 2, 1.0);
    int ia[] = {0, 1, 1, 2, 2}, ja[] = {0, 1, 2, 1, 2};
    double ar[] = {0, 1.0, 2.0, 3.0, 1.0};
    glp_load_matrix(lp, 4, ia, ja, ar);

    glp_smcp parm;
    glp_init_smcp(&parm);
    parm.msg_lev = GLP_MSG_OFF;
    glp_simplex(lp, &parm);
    int z = (int)glp_get_obj_val(lp);
    return cq_measure(z);
}
