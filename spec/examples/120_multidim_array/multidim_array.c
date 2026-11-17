#include <stdbool.h>
static const int GRID[4][4] = {{3, 1, 4, 1}, {5, 9, 2, 6}, {5, 3, 5, 8}, {9, 7, 9, 3}};
int table_2d(unsigned r0, unsigned c0, double tr, double tc) {
    unsigned r = r0, c = c0;
    cq_theta(&r, tr);
    cq_theta(&c, tc);
    return cq_measure(GRID[r & 3][c & 3]);            /* quantum row AND quantum column */
}
int register_grid(const double *theta, int rows, double c) {
    bool q[2][2] = {{0, 0}, {0, 0}};
    for (int i = 0; i < rows; i++)
        for (int j = 0; j < 2; j++)
            cq_theta(&q[i][j], theta[2 * i + j]);
    for (int i = 0; i < rows; i++)
        if (q[i][0])                                  /* controlled Ry inside a row */
            cq_theta(&q[i][1], c);
    if (q[0][1])                                      /* controlled Ry across rows */
        cq_theta(&q[rows - 1][1], c);
    return cq_measure(q[0][1]) + cq_measure(q[rows - 1][1]);
}
