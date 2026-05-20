#include "qint.h"
#define quantum __attribute__((annotate("quantum")))

int main(void) {
    qint_t x = init_qint(0, 16);                  // pattern 1
    qint_t y = init_qint(5, 16);              // pattern 2 (literal)
    int classic = 7;
    qint_t z = init_qint(classic, 16);        // pattern 2 (classical var)
    qint_t a = init_qint(3, 16); qint_t b = init_qint(2, 16);       // multi-decl, both pattern 2
    qint_t c = add(a, b);          // pattern 3 (Q + Q)
    qint_t d = add(a, init_qint(5, 16));          // pattern 4 (Q + classical literal)
    qint_t e = add(a, init_qint(classic, 16));    // pattern 4 (Q + classical var)
    return 0;
}
