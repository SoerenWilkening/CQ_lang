/* The Game of Life kernel as the program runs it (addPadding, then nextGen) on a ROWS x COLS torus whose first
 * QCELLS cells are each in superposition of dead and alive; the sizes and both arrays' addresses are classical.
 * GENS generations. Measures the centre cell. */
#include <stdbool.h>
#include <math.h>
#ifndef ROWS
#define ROWS 3
#endif
#ifndef COLS
#define COLS 3
#endif
#ifndef QCELLS
#define QCELLS 1
#endif
#ifndef GENS
#define GENS 1
#endif
void nextGen(bool automaton[], bool automatonPadded[], int row, int col);
void addPadding(bool automaton[], bool automatonPadded[], int row, int col);
int main(void) {
    bool a[ROWS * COLS] = {0}, p[(ROWS + 2) * (COLS + 2)];
    for (int i = 0; i < QCELLS; i++) {
        unsigned char q = 0;
        cq_theta(&q, M_PI_2);
        a[i] = q & 1;
    }
    for (int i = QCELLS; i < ROWS * COLS; i++)
        a[i] = i & 1;                           /* the rest: a fixed checkerboard */
    for (int g = 0; g < GENS; g++) {
        addPadding(a, p, ROWS, COLS);
        nextGen(a, p, ROWS + 2, COLS + 2);
    }
    return cq_measure((int)a[(ROWS / 2) * COLS + COLS / 2]);
}
